final: prev: {
  finix-bootctl = final.callPackage ./finix-bootctl { };
  fx = final.callPackage ./fx { };
}
