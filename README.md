# capacitor-plugin-tflite-cosines-calc

Do cosine similarity calculation of tensors to describe the fitness between text and images in clip model

## Install

```bash
npm install capacitor-plugin-tflite-cosines-calc
npx cap sync
```

## API

<docgen-index>

* [`echo(...)`](#echo)
* [`loadTensorFromDB(...)`](#loadtensorfromdb)
* [`offloadTensor(...)`](#offloadtensor)
* [`calculateCosineSimilarity(...)`](#calculatecosinesimilarity)

</docgen-index>

<docgen-api>
<!--Update the source file JSDoc comments and rerun docgen to update the docs below-->

### echo(...)

```typescript
echo(options: { value: string; }) => Promise<{ value: string; }>
```

| Param         | Type                            |
| ------------- | ------------------------------- |
| **`options`** | <code>{ value: string; }</code> |

**Returns:** <code>Promise&lt;{ value: string; }&gt;</code>

--------------------


### loadTensorFromDB(...)

```typescript
loadTensorFromDB(options: { emptyArg: number; }) => Promise<void>
```

| Param         | Type                               |
| ------------- | ---------------------------------- |
| **`options`** | <code>{ emptyArg: number; }</code> |

--------------------


### offloadTensor(...)

```typescript
offloadTensor(options: { emptyArg: number; }) => Promise<void>
```

| Param         | Type                               |
| ------------- | ---------------------------------- |
| **`options`** | <code>{ emptyArg: number; }</code> |

--------------------


### calculateCosineSimilarity(...)

```typescript
calculateCosineSimilarity(options: { tensorArray: number[]; }) => Promise<{ prob: number[]; }>
```

| Param         | Type                                    |
| ------------- | --------------------------------------- |
| **`options`** | <code>{ tensorArray: number[]; }</code> |

**Returns:** <code>Promise&lt;{ prob: number[]; }&gt;</code>

--------------------

</docgen-api>
