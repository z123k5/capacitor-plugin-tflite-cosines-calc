import Foundation
import Capacitor
import SQLite3
import TensorFlowLite

@objc(GalleryEnginePlugin)
public class GalleryEnginePlugin: CAPPlugin {
    private var db: OpaquePointer?
    private var similarity: TFLiteSimilarity?
    private var imageTensors: [Float]?

    override public func load() {
        super.load()
        CAPLog.print("GalleryEnginePlugin loaded")
    }

    deinit {
        if let db = db {
            CAPLog.print("Closing database connection")
            sqlite3_close(db)
        }
    }

    @objc func loadTensorFromDB(_ call: CAPPluginCall) {
        CAPLog.print("Starting to load tensors from database")
        do {
            similarity = try TFLiteSimilarity(modelName: "similarity_model")
            let dbPath = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)
                .first!
                .appendingPathComponent("CapacitorDatabase")
                .appendingPathComponent("mediaSQLite.db")
                .path
            CAPLog.print("Database path: \(dbPath)")

            if sqlite3_open_v2(dbPath, &db, SQLITE_OPEN_READWRITE, nil) != SQLITE_OK {
                call.reject("Error opening database")
                return
            }
            CAPLog.print("Database opened successfully")

            let query = "SELECT identifier, processStep, feature FROM media"
            var stmt: OpaquePointer?
            if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
                CAPLog.print("Executing query: \(query)")
                var featureList: [[Float]] = []

                while sqlite3_step(stmt) == SQLITE_ROW {
                    let processStep = sqlite3_column_int(stmt, 1)
                    CAPLog.print("Processing row with processStep: \(processStep)")
                    let feature: [Float]

                    if processStep == 2 {
                        if let blob = sqlite3_column_blob(stmt, 2) {
                            let dataSize = sqlite3_column_bytes(stmt, 2)
                            let data = Data(bytes: blob, count: Int(dataSize))
                            feature = byteArrayToFloatArray(data)
                            CAPLog.print("Loaded feature vector of size: \(feature.count)")
                        } else {
                            feature = [Float](repeating: 0.0, count: 768)
                            CAPLog.print("No feature data found, using zero vector")
                        }
                    } else {
                        feature = [Float](repeating: 0.0, count: 768)
                        CAPLog.print("processStep is not 2, using zero vector")
                    }

                    featureList.append(feature)
                }

                imageTensors = featureList.flatMap { $0 }
                CAPLog.print("Loaded image tensors with total size: \(imageTensors?.count ?? 0)")
                sqlite3_finalize(stmt)
                call.resolve()
            } else {
                if let errorMessage = sqlite3_errmsg(db) {
                    let errorStr = String(cString: errorMessage)
                    CAPLog.print("Failed to execute query " + errorStr)
                }
                call.reject("Query execution failed")
            }
        } catch {
            call.reject("Error loading Tensor", error.localizedDescription)
            CAPLog.print("Exception occurred: \(error.localizedDescription)")
        }
    }

    @objc func calculateCosineSimilarity(_ call: CAPPluginCall) {
        CAPLog.print("Starting cosine similarity calculation")
        guard let tensorArray = call.getArray("tensorArray", Double.self) else {
            call.reject("No tensor data provided")
            CAPLog.print("Error: No tensor data received")
            return
        }

        let tensorData = tensorArray.map { Float($0) }
        CAPLog.print("Received tensor data of size: \(tensorData.count)")

        guard let imageTensors = imageTensors else {
            call.reject("No image tensors loaded")
            CAPLog.print("Error: No image tensors available")
            return
        }

        do {
            let similarityScores = try similarity?.computeSimilarity(textFeatures: tensorData, imageFeatures: imageTensors) ?? []
            call.resolve(["prob": similarityScores])
        } catch {
            call.reject("Error calculating cosine similarity", error.localizedDescription)
            CAPLog.print("Exception occurred: \(error.localizedDescription)")
        }
    }

    @objc func offloadTensor(_ call: CAPPluginCall) {
        CAPLog.print("Releasing resources")
        if let db = db {
            sqlite3_close(db)
            self.db = nil
            CAPLog.print("Database connection closed")
        }
        similarity = nil
        imageTensors = nil
        CAPLog.print("Similarity model and tensors released")
        call.resolve()
    }

    private func byteArrayToFloatArray(_ data: Data) -> [Float] {
        let count = data.count / MemoryLayout<Float>.size
        CAPLog.print("Converting byte array to float array, size: \(count)")
        return data.withUnsafeBytes {
            Array(UnsafeBufferPointer<Float>(start: $0.bindMemory(to: Float.self).baseAddress, count: count))
        }
    }
}
