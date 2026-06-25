#include <napi.h>
#include <node_version.h>

namespace {

Napi::String Hello(const Napi::CallbackInfo &info) {
  return Napi::String::New(info.Env(), "hello from pinned node version example");
}

Napi::String GetVersion(const Napi::CallbackInfo &info) {
  return Napi::String::New(info.Env(), NODE_VERSION);
}

Napi::Object Init(Napi::Env env, Napi::Object exports) {
  exports.Set("hello", Napi::Function::New(env, Hello));
  exports.Set("getVersion", Napi::Function::New(env, GetVersion));
  return exports;
}

} // namespace

NODE_API_MODULE(version, Init)
