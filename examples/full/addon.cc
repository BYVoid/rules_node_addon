#include <chrono>
#include <napi.h>
#include <string>
#include <thread>
#include <utility>
#include <vector>

namespace {

Napi::String Hello(const Napi::CallbackInfo &info) {
  return Napi::String::New(info.Env(), "hello from full TypeScript example");
}

Napi::Value Add(const Napi::CallbackInfo &info) {
  Napi::Env env = info.Env();
  if (info.Length() < 2 || !info[0].IsNumber() || !info[1].IsNumber()) {
    Napi::TypeError::New(env, "add expects two numbers")
        .ThrowAsJavaScriptException();
    return env.Undefined();
  }

  const double left = info[0].As<Napi::Number>().DoubleValue();
  const double right = info[1].As<Napi::Number>().DoubleValue();
  return Napi::Number::New(env, left + right);
}

Napi::Array MakeNumberArray(Napi::Env env,
                            const std::vector<double> &numbers) {
  Napi::Array array = Napi::Array::New(env, numbers.size());
  for (size_t i = 0; i < numbers.size(); ++i) {
    array.Set(i, Napi::Number::New(env, numbers[i]));
  }
  return array;
}

Napi::Object MakeMetadata(const Napi::CallbackInfo &info) {
  Napi::Env env = info.Env();

  Napi::Object nested = Napi::Object::New(env);
  nested.Set("runtime", "node-addon-api");
  nested.Set("values", MakeNumberArray(env, {1, 2, 3}));

  const std::vector<uint8_t> bytes = {0x6e, 0x61, 0x70, 0x69};

  Napi::Object object = Napi::Object::New(env);
  object.Set("name", "full-example");
  object.Set("count", Napi::Number::New(env, 3));
  object.Set("enabled", Napi::Boolean::New(env, true));
  object.Set("tags", MakeNumberArray(env, {24, 14, 0}));
  object.Set("nested", nested);
  object.Set("bytes", Napi::Buffer<uint8_t>::Copy(env, bytes.data(), bytes.size()));
  object.Set("nothing", env.Null());
  return object;
}

Napi::Value SumArray(const Napi::CallbackInfo &info) {
  Napi::Env env = info.Env();
  if (info.Length() < 1 || !info[0].IsArray()) {
    Napi::TypeError::New(env, "sumArray expects an array")
        .ThrowAsJavaScriptException();
    return env.Undefined();
  }

  Napi::Array array = info[0].As<Napi::Array>();
  double sum = 0;
  for (uint32_t i = 0; i < array.Length(); ++i) {
    Napi::Value value = array.Get(i);
    if (!value.IsNumber()) {
      Napi::TypeError::New(env, "sumArray expects only numbers")
          .ThrowAsJavaScriptException();
      return env.Undefined();
    }
    sum += value.As<Napi::Number>().DoubleValue();
  }
  return Napi::Number::New(env, sum);
}

class CallbackWorker final : public Napi::AsyncWorker {
public:
  CallbackWorker(Napi::Function callback, int left, int right)
      : Napi::AsyncWorker(callback, "CallbackWorker"), left_(left),
        right_(right) {}

  void Execute() override {
    std::this_thread::sleep_for(std::chrono::milliseconds(1));
    result_ = left_ * right_;
  }

  void OnOK() override {
    Callback().Call({Env().Null(), Napi::Number::New(Env(), result_)});
  }

private:
  int left_;
  int right_;
  int result_ = 0;
};

Napi::Value MultiplyWithWorker(const Napi::CallbackInfo &info) {
  Napi::Env env = info.Env();
  if (info.Length() < 3 || !info[0].IsNumber() || !info[1].IsNumber() ||
      !info[2].IsFunction()) {
    Napi::TypeError::New(env,
                         "multiplyWithWorker expects two numbers and a callback")
        .ThrowAsJavaScriptException();
    return env.Undefined();
  }

  const int left = info[0].As<Napi::Number>().Int32Value();
  const int right = info[1].As<Napi::Number>().Int32Value();
  Napi::Function callback = info[2].As<Napi::Function>();

  auto *worker = new CallbackWorker(callback, left, right);
  worker->Queue();
  return env.Undefined();
}

class PromiseWorker final : public Napi::AsyncWorker {
public:
  PromiseWorker(Napi::Env env, std::string label, int value)
      : Napi::AsyncWorker(env, "PromiseWorker"),
        deferred_(Napi::Promise::Deferred::New(env)), label_(std::move(label)),
        value_(value) {}

  Napi::Promise Promise() const { return deferred_.Promise(); }

  void Execute() override {
    std::this_thread::sleep_for(std::chrono::milliseconds(1));
    doubled_ = value_ * 2;
  }

  void OnOK() override {
    Napi::Env env = Env();
    Napi::Object result = Napi::Object::New(env);
    result.Set("label", label_);
    result.Set("input", Napi::Number::New(env, value_));
    result.Set("doubled", Napi::Number::New(env, doubled_));
    result.Set("source", "promise-worker");
    deferred_.Resolve(result);
  }

  void OnError(const Napi::Error &error) override {
    deferred_.Reject(error.Value());
  }

private:
  Napi::Promise::Deferred deferred_;
  std::string label_;
  int value_;
  int doubled_ = 0;
};

Napi::Value GetAsyncReport(const Napi::CallbackInfo &info) {
  Napi::Env env = info.Env();
  if (info.Length() < 2 || !info[0].IsString() || !info[1].IsNumber()) {
    Napi::TypeError::New(env, "getAsyncReport expects a string and a number")
        .ThrowAsJavaScriptException();
    return env.Undefined();
  }

  auto *worker = new PromiseWorker(
      env, info[0].As<Napi::String>().Utf8Value(),
      info[1].As<Napi::Number>().Int32Value());
  Napi::Promise promise = worker->Promise();
  worker->Queue();
  return promise;
}

Napi::Object Init(Napi::Env env, Napi::Object exports) {
  exports.Set("hello", Napi::Function::New(env, Hello));
  exports.Set("add", Napi::Function::New(env, Add));
  exports.Set("makeMetadata", Napi::Function::New(env, MakeMetadata));
  exports.Set("sumArray", Napi::Function::New(env, SumArray));
  exports.Set("multiplyWithWorker", Napi::Function::New(env, MultiplyWithWorker));
  exports.Set("getAsyncReport", Napi::Function::New(env, GetAsyncReport));
  return exports;
}

} // namespace

NODE_API_MODULE(addon, Init)
