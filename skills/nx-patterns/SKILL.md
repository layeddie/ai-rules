---
name: nx-patterns
description: Nx and Livebook patterns for machine learning in Elixir
---

# Nx Patterns Skill

Use this skill when implementing machine learning features with Nx in Elixir applications.

## When to Use

- Building neural networks in Elixir
- Implementing ML inference
- Training models with Elixir
- GPU acceleration with EXLA
- Livebook integration
- Data preprocessing pipelines
- Model serving and deployment

## Overview

Nx is a multi-dimensional array library for Elixir with:
- Numerical computing capabilities
- Automatic differentiation
- JIT compilation with EXLA/Torchx
- GPU/TPU support
- Integration with Livebook

## Basic Setup

### Dependencies

```elixir
# mix.exs
def deps do
  [
    {:nx, "~> 0.7"},
    {:exla, "~> 0.7"},
    {:axon, "~> 0.6"},
    {:explorer, "~> 0.8"},
    {:scholar, "~> 0.3"},
    {:kino, "~> 0.12"}
  ]
end

# config/config.exs
import Config

config :nx, default_backend: EXLA.Backend
config :exla, :clients, default: [platform: :host]
```

## Neural Networks with Axon

### Simple Network

```elixir
# lib/my_app/ml/classifier.ex
defmodule MyApp.ML.Classifier do
  use Nx.Defn

  def create_model(input_shape, output_classes) do
    Axon.input({nil, input_shape})
    |> Axon.dense(128, activation: :relu)
    |> Axon.dropout(rate: 0.3)
    |> Axon.dense(64, activation: :relu)
    |> Axon.dropout(rate: 0.2)
    |> Axon.dense(output_classes, activation: :softmax)
  end

  def train(model, train_data, epochs \\ 10) do
    model
    |> Axon.Loop.trainer(:categorical_cross_entropy, Axon.Optimizers.adam(0.001))
    |> Axon.Loop.metric(:accuracy)
    |> Axon.Loop.run(train_data, epochs: epochs, compiler: EXLA)
  end

  def predict(model, params, input) do
    Axon.predict(model, params, input)
  end
end
```

### Convolutional Network

```elixir
# lib/my_app/ml/cnn.ex
defmodule MyApp.ML.CNN do
  def create_cnn(input_shape \\ {nil, 28, 28, 1}, num_classes \\ 10) do
    Axon.input(input_shape)
    |> Axon.conv(32, kernel_size: {3, 3}, activation: :relu)
    |> Axon.max_pool(kernel_size: {2, 2})
    |> Axon.conv(64, kernel_size: {3, 3}, activation: :relu)
    |> Axon.max_pool(kernel_size: {2, 2})
    |> Axon.flatten()
    |> Axon.dense(128, activation: :relu)
    |> Axon.dropout(rate: 0.5)
    |> Axon.dense(num_classes, activation: :softmax)
  end
end
```

### Recurrent Network

```elixir
# lib/my_app/ml/rnn.ex
defmodule MyApp.ML.RNN do
  def create_lstm(vocab_size, embedding_dim, hidden_dim, output_classes) do
    Axon.input({nil, nil})
    |> Axon.embedding(vocab_size, embedding_dim)
    |> Axon.lstm(hidden_dim)
    |> Axon.add(&elem(&1, 0))  # Take final hidden state
    |> Axon.dense(hidden_dim, activation: :tanh)
    |> Axon.dropout(rate: 0.4)
    |> Axon.dense(output_classes, activation: :softmax)
  end

  def create_gru(vocab_size, embedding_dim, hidden_dim, output_classes) do
    Axon.input({nil, nil})
    |> Axon.embedding(vocab_size, embedding_dim)
    |> Axon.gru(hidden_dim)
    |> Axon.add(&elem(&1, 0))
    |> Axon.dense(output_classes, activation: :softmax)
  end
end
```

## Data Preprocessing

### With Explorer

```elixir
# lib/my_app/ml/preprocessing.ex
defmodule MyApp.ML.Preprocessing do
  alias Explorer.DataFrame, as: DF
  alias Explorer.Series

  require DataFrame

  def load_and_preprocess(csv_path) do
    csv_path
    |> DF.read_csv!()
    |> handle_missing_values()
    |> normalize_columns()
    |> encode_categories()
  end

  defp handle_missing_values(df) do
    df
    |> DF.mutate(
      numeric_col: fill_missing(numeric_col, Series.mean(numeric_col)),
      categorical_col: fill_missing(categorical_col, "unknown")
    )
  end

  defp normalize_columns(df) do
    df
    |> DF.mutate(
      normalized: (numeric_col - Series.min(numeric_col)) / 
                  (Series.max(numeric_col) - Series.min(numeric_col))
    )
  end

  defp encode_categories(df) do
    df
    |> DF.mutate(
      category_encoded: cast(category, :integer)
    )
  end

  def to_tensor(df, columns) do
    df
    |> DF.select(columns)
    |> DF.to_numpy()
    |> Nx.tensor()
  end

  def split_data(data, train_ratio \\ 0.8) do
    n = Nx.axis_size(data, 0)
    train_size = floor(n * train_ratio)

    {data[0..train_size-1], data[train_size..-1//1]}
  end

  def batch_data(data, batch_size) do
    data
    |> Nx.to_batched(batch_size)
  end
end
```

### With Nx.Defn

```elixir
# lib/my_app/ml/transforms.ex
defmodule MyApp.ML.Transforms do
  import Nx.Defn

  defn normalize(x) do
    mean = Nx.mean(x)
    std = Nx.standard_deviation(x)
    (x - mean) / (std + 1.0e-8)
  end

  defn standardize(x) do
    min = Nx.reduce_min(x)
    max = Nx.reduce_max(x)
    (x - min) / (max - min)
  end

  defn one_hot_encode(labels, num_classes) do
    Nx.equal(
      Nx.reshape(labels, {:auto, 1}),
      Nx.iota({1, num_classes})
    )
  end

  defn augment_image(image) do
    # Random horizontal flip
    should_flip = Nx.random_uniform({}) |> Nx.greater(0.5)
    
    flipped = Nx.reverse(image, axes: [1])
    
    # Random rotation (simplified)
    angle = Nx.random_uniform({}, min: -0.1, max: 0.1)
    # Rotation implementation would go here
    
    Nx.select(should_flip, flipped, image)
  end
end
```

## Model Serving

### GenServer for Model Serving

```elixir
# lib/my_app/ml/model_server.ex
defmodule MyApp.ML.ModelServer do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def predict(input) do
    GenServer.call(__MODULE__, {:predict, input})
  end

  def batch_predict(inputs) do
    GenServer.call(__MODULE__, {:batch_predict, inputs})
  end

  # Server callbacks

  def init(opts) do
    model_path = Keyword.fetch!(opts, :model_path)
    
    # Load model and parameters
    {model, params} = load_model(model_path)
    
    state = %{
      model: model,
      params: params,
      batch_size: Keyword.get(opts, :batch_size, 32)
    }
    
    {:ok, state}
  end

  def handle_call({:predict, input}, _from, state) do
    result = do_predict(state.model, state.params, input)
    {:reply, result, state}
  end

  def handle_call({:batch_predict, inputs}, _from, state) do
    results = 
      inputs
      |> Nx.stack()
      |> do_predict(state.model, state.params)
    
    {:reply, results, state}
  end

  defp load_model(path) do
    # Load Axon model and parameters
    params = File.read!(Path.join(path, "params.bin"))
    |> :erlang.binary_to_term()
    
    model = load_model_structure(Path.join(path, "model.ex"))
    
    {model, params}
  end

  defp load_model_structure(path) do
    {model, _} = Code.eval_file(path)
    model
  end

  defp do_predict(model, params, input) do
    Axon.predict(model, params, input)
  end
end

# Add to application supervisor
defmodule MyApp.Application do
  def start(_type, _args) do
    children = [
      {MyApp.ML.ModelServer, model_path: "/path/to/model", batch_size: 64}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
```

### REST API for Model Serving

```elixir
# lib/my_app_web/controllers/ml_controller.ex
defmodule MyAppWeb.MLController do
  use MyAppWeb, :controller

  def predict(conn, %{"input" => input_data}) do
    # Parse input
    input = parse_input(input_data)
    
    # Make prediction
    result = MyApp.ML.ModelServer.predict(input)
    
    # Format response
    json(conn, %{
      prediction: Nx.to_list(result),
      confidence: get_confidence(result)
    })
  end

  def batch_predict(conn, %{"inputs" => inputs}) do
    # Parse inputs
    parsed_inputs = Enum.map(inputs, &parse_input/1)
    
    # Batch prediction
    results = MyApp.ML.ModelServer.batch_predict(parsed_inputs)
    
    json(conn, %{
      predictions: Nx.to_list(results)
    })
  end

  defp parse_input(data) when is_list(data) do
    Nx.tensor(data)
  end

  defp parse_input(%{"values" => values, "shape" => shape}) do
    values
    |> Nx.tensor()
    |> Nx.reshape(shape)
  end

  defp get_confidence(logits) do
    logits
    |> Nx.argmax()
    |> Nx.to_number()
  end
end
```

## GPU Acceleration

### EXLA Configuration

```elixir
# config/runtime.exs
import Config

# GPU configuration
config :exla, :clients,
  cuda: [
    platform: :cuda,
    memory_fraction: 0.9,
    preallocate: true
  ],
  rocm: [
    platform: :rocm,
    memory_fraction: 0.85
  ],
  host: [
    platform: :host,
    num_threads: System.schedulers_online()
  ]

# Default to GPU if available
config :nx, default_backend: {EXLA.Backend, client: :cuda}

# Fallback configuration
config :nx, default_backend: EXLA.Backend
```

### Multi-GPU Training

```elixir
# lib/my_app/ml/distributed_training.ex
defmodule MyApp.ML.DistributedTraining do
  def train_on_multiple_gpus(model, data, num_gpus) do
    # Split data across GPUs
    batches_per_gpu = Nx.axis_size(data, 0) |> div(num_gpus)
    
    # Create tasks for each GPU
    tasks = 
      for gpu_id <- 0..(num_gpus - 1) do
        start_idx = gpu_id * batches_per_gpu
        end_idx = start_idx + batches_per_gpu - 1
        gpu_data = data[start_idx..end_idx]
        
        Task.async(fn ->
          train_on_device(model, gpu_data, gpu_id)
        end)
      end
    
    # Collect results
    results = Task.await_many(tasks, :infinity)
    
    # Average gradients
    averaged_params = average_parameters(results)
    
    averaged_params
  end

  defp train_on_device(model, data, device_id) do
    client_name = :"cuda_#{device_id}"
    
    model
    |> Axon.Loop.trainer(:mean_squared_error, Axon.Optimizers.adam(0.001))
    |> Axon.Loop.run(data, 
      epochs: 1, 
      compiler: {EXLA, client: client_name}
    )
  end

  defp average_parameters(params_list) do
    # Average parameters from all GPUs
    params_list
    |> Enum.zip()
    |> Enum.map(fn tuple ->
      tuple
      |> Tuple.to_list()
      |> Enum.reduce(&Nx.add/2)
      |> Nx.divide(length(params_list))
    end)
  end
end
```

## Livebook Integration

### Interactive Model Development

```elixir
# livebook/model_development.livemd
# ---
# livebook: {"persist_outputs": true, "auto_imports": ["Kino", "Explorer", "Nx"]}
# ---

# Load dependencies
Mix.install([
  {:nx, "~> 0.7"},
  {:exla, "~> 0.7"},
  {:axon, "~> 0.6"},
  {:explorer, "~> 0.8"},
  {:kino, "~> 0.12"}
])

# Configure Nx
Nx.default_backend(EXLA.Backend)

# Load and explore data
alias Explorer.DataFrame, as: DF

data = DF.read_csv!("/path/to/data.csv")
DF.head(data)
DF.describe(data)

# Visualize data
VegaLite.new(width: 400, height: 300)
|> VegaLite.data_from_values(data)
|> VegaLite.mark(:point)
|> VegaLite.encode_field(:x, "feature_1", type: :quantitative)
|> VegaLite.encode_field(:y, "feature_2", type: :quantitative)

# Preprocess
tensors = MyApp.ML.Preprocessing.to_tensor(data, [:feature_1, :feature_2, :label])
{train_data, test_data} = MyApp.ML.Preprocessing.split_data(tensors, 0.8)

# Create model
model = MyApp.ML.Classifier.create_model(2, 2)

# Visualize model
Axon.Display.as_graph(model, %{})

# Train model
IO.puts("Training model...")
{model, params} = MyApp.ML.Classifier.train(model, train_data, epochs: 20)

# Evaluate
predictions = MyApp.ML.Classifier.predict(model, params, test_data)

# Visualize predictions
Kino.render(predictions)

# Save model
Axon.save(model, params, "/path/to/save")
```

### Hyperparameter Tuning

```elixir
# livebook/hyperparameter_tuning.livemd
defmodule HyperparameterSearch do
  def grid_search(model_fn, train_data, val_data, param_grid) do
    for learning_rate <- param_grid.learning_rates,
        batch_size <- param_grid.batch_sizes,
        hidden_dim <- param_grid.hidden_dims do
      
      # Create model with current hyperparameters
      model = model_fn.(hidden_dim)
      
      # Train with current hyperparameters
      {model, params} = 
        model
        |> Axon.Loop.trainer(:mean_squared_error, Axon.Optimizers.adam(learning_rate))
        |> Axon.Loop.metric(:mean_squared_error, :mse)
        |> Axon.Loop.run(train_data, 
          epochs: 10, 
          batch_size: batch_size,
          compiler: EXLA
        )
      
      # Evaluate on validation set
      val_loss = evaluate(model, params, val_data)
      
      %{
        learning_rate: learning_rate,
        batch_size: batch_size,
        hidden_dim: hidden_dim,
        val_loss: val_loss
      }
    end
  end

  defp evaluate(model, params, data) do
    predictions = Axon.predict(model, params, data)
    Nx.mean(Nx.power(data - predictions, 2))
  end
end

# Define parameter grid
param_grid = %{
  learning_rates: [0.001, 0.01, 0.1],
  batch_sizes: [16, 32, 64],
  hidden_dims: [32, 64, 128]
}

# Run grid search
results = HyperparameterSearch.grid_search(
  &create_model/1,
  train_data,
  val_data,
  param_grid
)

# Find best hyperparameters
best = Enum.min_by(results, & &1.val_loss)
IO.puts("Best hyperparameters: #{inspect(best)}")
```

## Model Optimization

### Quantization

```elixir
# lib/my_app/ml/quantization.ex
defmodule MyApp.ML.Quantization do
  def quantize_model(params, precision \\ :half) do
    case precision do
      :half -> quantize_to_fp16(params)
      :int8 -> quantize_to_int8(params)
    end
  end

  defp quantize_to_fp16(params) do
    Nx.Defn.jit(&do_quantize_fp16/1, [params])
  end

  defnp do_quantize_fp16(x) do
    Nx.as_type(x, :f16)
  end

  defp quantize_to_int8(params) do
    # Quantize weights to int8 for inference
    for layer <- params do
      quantize_layer(layer)
    end
  end

  defp quantize_layer(layer) do
    # Quantization with scale factors
    min_val = Nx.reduce_min(layer)
    max_val = Nx.reduce_max(layer)
    scale = (max_val - min_val) / 255
    
    quantized = 
      layer
      |> Nx.subtract(min_val)
      |> Nx.divide(scale)
      |> Nx.round()
      |> Nx.as_type(:s8)
    
    {quantized, scale, min_val}
  end
end
```

### Model Pruning

```elixir
# lib/my_app/ml/pruning.ex
defmodule MyApp.ML.Pruning do
  def prune_model(params, threshold \\ 0.01) do
    for layer <- params do
      prune_layer(layer, threshold)
    end
  end

  defp prune_layer(layer, threshold) do
    # Compute absolute values
    abs_weights = Nx.abs(layer)
    
    # Create mask for weights above threshold
    mask = Nx.greater(abs_weights, threshold)
    
    # Apply mask
    Nx.select(mask, layer, 0)
  end

  def structured_pruning(model, params, prune_ratio) do
    # Prune entire channels/filters
    # Implementation depends on model architecture
    model
  end
end
```

## Testing ML Models

```elixir
# test/my_app/ml/classifier_test.exs
defmodule MyApp.ML.ClassifierTest do
  use ExUnit.Case

  setup do
    Nx.default_backend(EXLA.Backend)
    :ok
  end

  test "creates model with correct architecture" do
    model = MyApp.ML.Classifier.create_model(10, 2)
    
    # Check model has expected layers
    assert %{output_shape: {nil, 2}} = Axon.get_output_shape(model)
  end

  test "trains model and improves accuracy" do
    # Create dummy data
    train_data = generate_dummy_data(100, 10, 2)
    
    model = MyApp.ML.Classifier.create_model(10, 2)
    
    {trained_model, params} = MyApp.ML.Classifier.train(model, train_data, epochs: 5)
    
    # Check model is trained
    assert is_map(params)
  end

  test "predicts output shape" do
    model = MyApp.ML.Classifier.create_model(10, 2)
    
    # Initialize random parameters
    params = Axon.init(model)
    
    input = Nx.random_uniform({1, 10})
    output = MyApp.ML.Classifier.predict(model, params, input)
    
    assert Nx.shape(output) == {1, 2}
  end

  defp generate_dummy_data(n_samples, input_dim, output_dim) do
    inputs = Nx.random_uniform({n_samples, input_dim})
    labels = Nx.random_uniform({n_samples, output_dim})
    
    {inputs, labels}
  end
end
```

## Best Practices

### Model Development

1. **Start simple** - Begin with small networks
2. **Use validation data** - Prevent overfitting
3. **Monitor metrics** - Track loss and accuracy
4. **Use batch normalization** - Stabilize training
5. **Apply dropout** - Regularization

### Performance

1. **Use EXLA** - JIT compilation
2. **Batch data** - Efficient processing
3. **Preallocate memory** - Avoid allocation overhead
4. **Use mixed precision** - Faster training
5. **Profile before optimizing** - Identify bottlenecks

### Deployment

1. **Quantize models** - Reduce size
2. **Cache compiled functions** - Avoid recompilation
3. **Use model servers** - Efficient inference
4. **Monitor performance** - Track latency
5. **Version models** - Track experiments

## Related Skills

- **data-pipeline**: Data preprocessing
- **performance-profiling**: Profiling ML models
- **testing**: Testing ML models
- **liveview-patterns**: Real-time ML visualization
