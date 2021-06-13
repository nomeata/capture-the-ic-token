Capture The IC Token
====================

This little project implements a canister that will hold on to **1 ICP** and
reveal it to anyone who can guess a secret. The secret is obtained from the
Internet Computer’s random tape (using the `aaaaa-aa.raw_rand()` call), and
then kept in main memory. If you find a way to read from the secret tape, or
from the canister’s main memory you unlock one ICP.

The canister is live with canister id **TODO** (not live yet).

The ICP is sitting in account **TODO** owned by principal **TODO**.

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

You still have to do a little bit of coding. Here is a rough outline:

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

Are you really running the code you claim to run?
-------------------------------------------------

You can check yourself! See the [blog post about verifying the Internet
Identity](https://medium.com/dfinity/verifying-the-internet-identity-code-a-walkthrough-c1dd7a53f883)
for a rough outline. I used dfx-0.7.0 (moc-0.6.1) on Linux to build this canister.

Who is the controller of this canister?
---------------------------------------

No one (you can check with `dfx canister info`).

The canister reports its cycle balance at <https://TODO.raw.ic0.app/>. Feel
free to donate a few cycles.  If this canister runs out of cycles and gets
removed by the system, the ICP prize is lost forever.

Are Canister Signaures even supported yet?
------------------------------------------

The [Interface Spec] specifies them on all subnets, but the replica, at the
time of writing, only accepts them from canisters on the root subnet. This
restriction is currently implemented in [these
lines](https://github.com/dfinity/ic/blob/779549eccfcf61ac702dfc2ee6d76ffdc2db1f7f/rs/certified_vars/src/lib.rs#L94-L96),
and will be removed soon™. If you indeed manage to get the secret before this
restriction is removed, well, be proud of it.

More questions?
---------------

I have enabled the discussion feature on this repository, feel free to use it.
Else <https://forum.dfinity.org/> is a fine venue for questions.

