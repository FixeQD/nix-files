{ lib, fetchFromGitHub, stdenv, makeBinaryWrapper, zig }:

stdenv.mkDerivation {
  pname = "fx";
  version = "0.0.4";

  src = fetchFromGitHub {
    owner = "vercel-labs";
    repo = "fx";
    rev = "v0.0.4";
    hash = "sha256-NeDAx55Ws3pZJeug8rYEFQaMI2Kf1Smz07nwhhiL+WM=";
  };

  nativeBuildInputs = [ makeBinaryWrapper zig ];

  buildPhase = ''
    runHook preBuild
    zig build -Doptimize=ReleaseSafe
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 zig-out/bin/fx "$out/bin/fx"
    runHook postInstall
  '';

  postInstall = ''
    install -Dm444 LICENSE "$out/share/licenses/fx/LICENSE"
    install -Dm444 THIRD_PARTY_NOTICES.md "$out/share/licenses/fx/THIRD_PARTY_NOTICES.md"
  '';

  postFixup = "wrapProgram $out/bin/fx --set FX_AUTO_UPGRADE 0";

  meta = {
    description = "Terminal JSON viewer + processing tool";
    homepage = "https://github.com/vercel-labs/fx";
    license = lib.licenses.asl20;
    platforms = lib.platforms.unix;
    mainProgram = "fx";
  };
}
