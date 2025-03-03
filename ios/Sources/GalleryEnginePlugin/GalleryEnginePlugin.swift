import Foundation
import Capacitor
import SQLite3
import TensorFlowLite

/**
 * Please read the Capacitor iOS Plugin Development Guide
 * here: https://capacitorjs.com/docs/plugins/ios
 */
@objc(GalleryEnginePlugin)
public class GalleryEnginePlugin: CAPPlugin {
    private var db: OpaquePointer?
    private var similarity: TFLiteSimilarity?
    private var imageTensors: [Float]?

    override public func load() {
        super.load()
    }

    deinit {
        if let db = db {
            sqlite3_close(db)
        }
    }

    // 从数据库加载 Tensor
    @objc func loadTensorFromDB(_ call: CAPPluginCall) {
        do {
            similarity = try TFLiteSimilarity(modelName: "similarity_model")

            let dbPath = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!.appendingPathComponent("mediaSQLite.db").path
            if sqlite3_open(dbPath, &db) != SQLITE_OK {
                call.reject("Error opening database")
                return
            }

            let query = "SELECT identifier, processStep, feature FROM media"
            var stmt: OpaquePointer?
            if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
                var featureList: [[Float]] = []

                while sqlite3_step(stmt) == SQLITE_ROW {
                    let processStep = sqlite3_column_int(stmt, 1)
                    let feature: [Float]

                    if processStep == 2 {
                        if let blob = sqlite3_column_blob(stmt, 2) {
                            let dataSize = sqlite3_column_bytes(stmt, 2)
                            let data = Data(bytes: blob, count: Int(dataSize))
                            feature = byteArrayToFloatArray(data)
                        } else {
                            feature = [Float](repeating: 0.0, count: 768)
                        }
                    } else {
                        feature = [Float](repeating: 0.0, count: 768)
                    }

                    featureList.append(feature)
                }

                imageTensors = featureList.flatMap { $0 }
                sqlite3_finalize(stmt)
                call.resolve()
            } else {
                call.reject("Query execution failed")
            }
        } catch {
            call.reject("Error loading Tensor", error.localizedDescription)
        }
    }

    // 计算余弦相似度
    @objc func calculateCosineSimilarity(_ call: CAPPluginCall) {
        guard let tensorArray = call.getArray("tensorArray", Double.self) else {
            call.reject("No tensor data provided")
            return
        }

        let tensorData = tensorArray.map { Float($0) }
        guard let imageTensors = imageTensors else {
            call.reject("No image tensors loaded")
            return
        }

        do {
            let similarityScores = try similarity?.computeSimilarity(textFeatures: tensorData, imageFeatures: imageTensors) ?? []
            call.resolve([
                "prob": similarityScores
            ])
        } catch {
            call.reject("Error calculating cosine similarity", error.localizedDescription)
        }
    }

    // 释放资源
    @objc func offloadTensor(_ call: CAPPluginCall) {
        if let db = db {
            sqlite3_close(db)
            self.db = nil
        }
        similarity = nil
        imageTensors = nil
        call.resolve()
    }

    // 将字节数组转换为 Float 数组
    private func byteArrayToFloatArray(_ data: Data) -> [Float] {
        let count = data.count / MemoryLayout<Float>.size
        return data.withUnsafeBytes {
            Array(UnsafeBufferPointer<Float>(start: $0.bindMemory(to: Float.self).baseAddress, count: count))
        }
    }
}