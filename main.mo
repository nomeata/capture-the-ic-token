import T "mo:base/Text";
import O "mo:base/Option";
import Blob "mo:base/Blob";
import Error "mo:base/Error";
import Principal "mo:base/Principal";
import CertifiedData "mo:base/CertifiedData";
import ExperimentalCycles "mo:base/ExperimentalCycles";
import SHA256 "mo:sha256/SHA256";
import Random "mo:base/Random";

actor {
  var secret : ?Blob = null;
  var unsuccessful_calls = 0;
  var successful_calls = 0;

  type HeaderField = (Text, Text);

  type HttpResponse = {
    status_code: Nat16;
    headers: [HeaderField];
    body: Blob;
  };

  // can hopefully be simplified once
  // https://github.com/dfinity-lab/motoko/issues/966 is resolved
  func sha256(b1 : Blob, b2 : Blob) : Blob {
    let d = SHA256.Digest();
    d.write(Blob.toArray(b1));
    d.write(Blob.toArray(b2));
    Blob.fromArray(d.sum());
  };


  public func load_secret() : async () {
    if (O.isSome(secret)) {
      throw Error.reject("Secret already set")
    };
    let b = await Random.blob();
    if (O.isSome(secret)) {
      throw Error.reject("Secret suddenly set. Did I lose some race?")
    };
    secret := ?b;
  };

  public shared({caller}) func set_certified_data(hash : Blob, data : Blob) : async () {
    switch secret {
      case (?s) {
        if (sha256(Principal.toBlob(caller), hash) == s) {
          successful_calls += 1;
          CertifiedData.set(data)
        } else {
          unsuccessful_calls += 1;
          throw Error.reject("Sorry, wrong hash")
        }
      };
      case null {
        ignore (load_secret()); // NB: No await
        throw Error.reject("Secret was not set, trying to set that now.")
      }
    }
  };

  public query func get_certificate() : async Blob {
    switch (CertifiedData.getCertificate()) {
      case (?c) c;
      case null (throw Error.reject("getCertificate failed. Call this as a query call!"))
    }
  };

  public query func http_request() : async HttpResponse {
    return {
      status_code = 200;
      headers = [("content-type", "text/plain")];
      body = T.encodeUtf8 (
        "This is nomeata's capture-the-ic-token canister.\n" #
        "See https://github.com/nomeata/capture-the-ic-token for details.\n" #
        "\n" #
        "My current cycle balance:                " # debug_show (ExperimentalCycles.balance()) # "\n" #
        "Secret loaded from secret tape:          " # debug_show (O.isSome(secret)) # "\n" #
        "Sucessful calls to set_certified_data:   " # debug_show successful_calls # "\n" #
        "Unsucessful calls to set_certified_data: " # debug_show unsuccessful_calls # "\n"
      )
    }
  };
};
