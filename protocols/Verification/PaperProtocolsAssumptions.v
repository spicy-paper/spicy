(*
 * SPDX-License-Identifier: MIT
 * 
 *)

From SPICY Require Import
     ModelCheck.SilentStepElimination
.

From protocols Require Import
     Verification.ShareSecretProtocolSymmetricEncSecure
     Verification.PGPSecure
     Verification.SecureDNSSecure
     Verification.AggregationSecure
     Verification.NetAuthSecure
.

Set Implicit Arguments.

Module ShareSecretCorrect := SSProtocolSimulates (ShareSecretProtocolSecureSS).
Print Assumptions ShareSecretCorrect.protocol_with_adversary_could_generate_spec.

Module PGPCorrect := SSProtocolSimulates (PGPProtocolSecure).
Print Assumptions PGPCorrect.protocol_with_adversary_could_generate_spec.

Module SecureDNSCorrect := SSProtocolSimulates (SecureDNSProtocolSecure).
Print Assumptions SecureDNSCorrect.protocol_with_adversary_could_generate_spec.

Module AggregationCorrect := SSProtocolSimulates (AggregationProtocolSecure).
Print Assumptions AggregationCorrect.protocol_with_adversary_could_generate_spec.

Module NetAuthCorrect := SSProtocolSimulates (NetAuthProtocolSecure).
Print Assumptions NetAuthCorrect.protocol_with_adversary_could_generate_spec.
