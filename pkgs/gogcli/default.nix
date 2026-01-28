{
  lib,
  buildGoModule,
  source,
  ...
}:

buildGoModule rec {
  inherit (source) pname version src;
  vendorHash = "sha256-nig3GI7eM1XRtIoAh1qH+9PxPPGynl01dCZ2ppyhmzU=";
  checkFlags =
    let
      skippedTests = [
        # internal/googleauth - OAuth flow tests requiring network/ports
        "TestAuthorize_Manual_Success"
        "TestAuthorize_Manual_Success_NoNewline"
        "TestAuthorize_Manual_CancelEOF"
        "TestAuthorize_Manual_StateMismatch"
        "TestAuthorize_ServerFlow_Success"
        "TestAuthorize_ServerFlow_CallbackErrors"
        "TestManageServer_HandleOAuthCallback_ErrorAndValidation"
        "TestManageServer_HandleOAuthCallback_Success"
        "TestManageServer_HandleOAuthCallback_FileBackendSkipsKeychain"
        "TestManageServer_HandleOAuthCallback_Success_IDTokenEmail"
        "TestManageServer_HandleAuthStart"
        "TestManageServer_HandleAuthUpgrade"
        "TestFetchUserEmail"
        "TestStartManageServer_Timeout"
        "TestManageServerHandleOAuthCallback_ReadCredsError"
        "TestManageServerHandleOAuthCallback_ScopesError"
        "TestManageServerHandleOAuthCallback_ExchangeError"
        "TestManageServerHandleOAuthCallback_MissingRefreshToken"
        "TestManageServerHandleOAuthCallback_FetchEmailError"
        "TestCheckRefreshTokenSuccess"
        "TestCheckRefreshTokenFailure"
        # internal/cmd - Gmail watch tests requiring network
        "TestGmailWatchStartCmd_JSON"
        "TestGmailWatchServeCmd_UsesStoredHook"
        "TestGmailWatchServeCmd_DefaultMaxBytes"
      ];
    in
    [ "-skip=^${lib.concatStringsSep "$|^" skippedTests}$" ];
  ldflags =
    let
      mod = "github.com/steipete/gogcli/internal/cmd";
    in
    [
      "-s"
      "-w"
      "-X ${mod}.version=${version}"
      "-X ${mod}.commit=${src.rev}"
    ];
  meta = {
    description = "Fast, script-friendly CLI for Google Workspace (Gmail, Calendar, Drive, Docs, etc.)";
    homepage = "https://github.com/steipete/gogcli";
    license = lib.licenses.mit;
    mainProgram = "gog";
  };
}
