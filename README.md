Capture The IC Token
====================

This little project implements a canister that will hold on to **1 ICP** and
reveal it to anyone who can guess a secret. The secret is obtained from the
Internet Computer’s random tape (using the `aaaaa-aa.raw_rand()` call), and
then kept in main memory. If you find a way to read from the secret tape, or
from the canister’s main memory you unlock one ICP.

The canister is live with canister id [**fj6bh-taaaa-aaaab-qaacq-cai**](https://fj6bh-taaaa-aaaab-qaacq-cai.raw.ic0.app/).

The ICP is sitting in account [**62c01571c33e6b6d118842e2bc25193d6730f6a05580c64d4438411062f13310**](https://dashboard.internetcomputer.org/account/62c01571c33e6b6d118842e2bc25193d6730f6a05580c64d4438411062f13310) owned by principal **cjt7z-jev62-yoecz-5uvop-y5gys-qll6h-2atgr-df2hv-wspla-dbwm7-kqe**.

FAQ
===

Why?
----

Because it seemed like a nice programming puzzle. Also, to demonstrate a few
features of the Internet Computer, namely

 * The random tape
 * Certified data
 * [Canister Signatures]
 * Writing canisters in Motoko

[Canister Signatures]: https://sdk.dfinity.org/docs/interface-spec/index.html#canister-signatures

Did someone hack this already?
------------------------------

Hopefully not! You can check [the
account](https://dashboard.internetcomputer.org/account/62c01571c33e6b6d118842e2bc25193d6730f6a05580c64d4438411062f13310)
if the token is still there, and you can go to
<https://fj6bh-taaaa-aaaab-qaacq-cai.raw.ic0.app/> and see if there were any
“Successful calls to set_certified_data”.

I heard canisters cannot hold ICPs. How does this work?
------------------------------------------------------

Indeed, at the time of writing the ledger will not allow accounts owned by
canister ids, so Canisters cannot own ICPs via their canister id (which is a
principal).

But canisters can also create [Canister Signatures], a “signature scheme” based
on certified variables, and mainly used by identity providers such as
[Internet Identity]. The canister gives full control to its certified variables
to anyone who has guessed the secret, and thus those can sign withdrawal
requests towards the ledger.

[Internet Identity]: https://github.com/dfinity/internet-identity

I know the secret, how do I get the ICP?
----------------------------------------

You still have to do a little bit of coding, which is part of the exercise.
Here is a rough outline:

 * Create a request to transfer the token to your account.
 * Create a hash tree that contains a signature to this request in
   `/sig//<m>` (note that the seed is empty).
 * Pass the root hash of that tree to `set_certified_data`. To authorize, you
   have to also pass the hash of the concatenation of _your_ principal (in
   binary form) and the secret hash.
 * Use `get_certificate` to get the certificate
 * Construct a canister signature from the certificate and your hash tree
 * Submit this to the Internet Computer
 * Profit

If you like the programming challenge even without finding a bug in the
Internet Computer, and have implemented a tool for this, feel free to link to
it here.

Are you really running the code you claim to run?
-------------------------------------------------

You can check yourself! See the [blog post about verifying the Internet
Identity](https://medium.com/dfinity/verifying-the-internet-identity-code-a-walkthrough-c1dd7a53f883)
for a rough outline. I used dfx-0.7.0 (moc-0.6.1) on Linux to build this canister.

Who is the controller of this canister?
---------------------------------------

No one. You can check with `dfx canister info` or on [ic.rocks](https://ic.rocks/principal/fj6bh-taaaa-aaaab-qaacq-cai).

If you see `zrl4w-cqaaa-nocon-troll-eraaa-d5qc` shown as a controller, then you
are using a tool that does not speak the latest IC protocol. This is a
placeholder princpal (note that it says “no controller” in the middle).


The canister reports its cycle balance at
<https://fj6bh-taaaa-aaaab-qaacq-cai.raw.ic0.app/>. Feel free to donate a few
cycles.  If this canister runs out of cycles and gets removed by the system,
the ICP prize is lost forever.

Why does this canister control some canisters?
----------------------------------------------

Becuase I was given this canister by a colleage who was using this as a wallet
canister, but does not use it any more. Guess these controlled canisters are
now also orphans.

Are Canister Signaures even supported yet?
------------------------------------------

The [Interface Spec] specifies them on all subnets, but the replica, at the
time of writing, only accepts them from canisters on the root subnet. This
restriction is currently implemented in [these
lines](https://github.com/dfinity/ic/blob/779549eccfcf61ac702dfc2ee6d76ffdc2db1f7f/rs/certified_vars/src/lib.rs#L94-L96),
and will be removed soon™. If you indeed manage to get the secret before this
restriction is removed, well, be proud of it.

How did you calculate the principal and account number?
-------------------------------------------------------

The principal “owning” the token is derived from a Canister Signature public “key”, with the empty blob as the seed. From that we can calculate the ICP ledger address (with subaccount 0).

I used the code in [`dfinity/ic-hs`](https://github.com/dfinity/ic-hs) for these calculations:

```
~/dfinity/ic-hs $ cabal repl
> :set -XOverloadedStrings
> import Codec.Candid
> let Right (Principal raw_canister) = parsePrincipal "fj6bh-taaaa-aaaab-qaacq-cai"
> let raw_principal = IC.Id.Forms.mkSelfAuthenticatingId (IC.Crypto.CanisterSig.genPublicKey ((\(Right (Principal p)) -> EntityId p) (parsePrincipal "fj6bh-taaaa-aaaab-qaacq-cai")) "")
> prettyPrincipal (Principal raw_principal)
"cjt7z-jev62-yoecz-5uvop-y5gys-qll6h-2atgr-df2hv-wspla-dbwm7-kqe"
> import qualified Data.ByteString.Lazy as BS
> let subaccount = BS.replicate 32 0
> let account_hash = IC.Hash.sha224 ("\x0a" <> "account-id" <> raw_principal <> subaccount)
> import Data.Digest.CRC32
> let CRC32 checksum = digest (BS.toStrict account_hash)
> import qualified Data.ByteString.Builder as BS
> let checkbytes = BS.toLazyByteString (BS.word32BE checksum)
> import qualified Text.Hex as T
> T.encodeHex (BS.toStrict (checkbytes <> account_hash))
"62c01571c33e6b6d118842e2bc25193d6730f6a05580c64d4438411062f13310"
```

(And [ic.rocks](https://ic.rocks/principal/cjt7z-jev62-yoecz-5uvop-y5gys-qll6h-2atgr-df2hv-wspla-dbwm7-kqe) nicely confirms this calculation.)

What happens if I transfer funds to that account?
-------------------------------------------------

They will up the stakes for this treasure hunt, so feel free to! But note that
very likely, these tokens would simply be lost.

Also, should the subnet hosting this canister ever get reset, or Canister Signatures not implemented as planned, the tokens would be lost.

More questions or comments?
---------------------------

I have enabled the discussion feature on this repository, feel free to use it.
Else <https://forum.dfinity.org/> is a fine venue for questions.

