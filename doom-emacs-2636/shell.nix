{ pkgs ? import <nixpkgs> {} }:

let
  good-ref = "7cd9e55c8cc816ddb1256d40f590840e5d6e9bbf";
  bad-ref = "c311d798ce9ca64404926ad4d5be25edc35ded60";
  fixed-ref = "29650a67a28692d73fa6088b47ad78df052ad5fc";

  overrides = self: super: {
    lsp-mode = super.lsp-mode.overrideAttrs (
      old: {
        src = builtins.fetchTarball "https://github.com/emacs-lsp/lsp-mode/archive/fc812bea1f825e96190b84902352b34255837f67.tar.gz";
      }
    );
  };

  emacsOverlay = import (builtins.fetchTarball "https://github.com/nix-community/emacs-overlay/archive/master.tar.gz") pkgs pkgs;
  emacsPackages = emacsOverlay.emacsPackagesFor pkgs.emacs;

  nix-doom-emacs = ref: pkgs.callPackage (
    builtins.fetchTarball {
      url = https://github.com/vlaci/nix-doom-emacs/archive/master.tar.gz;
    }
  ) {
    bundledPackages = false;
    emacsPackages = (emacsPackages.overrideScope' overrides);
    dependencyOverrides = {
      doom-emacs = builtins.fetchTarball "https://github.com/hlissner/doom-emacs/archive/${ref}.tar.gz";
    };
    doomPrivateDir = ./doom.d;
  };
  shell = ref: pkgs.mkShell {
    buildInputs = with pkgs; [
      (python3.withPackages (ps: [ ps.python-language-server ]))
      (nix-doom-emacs ref)
    ];
    shellHook = ''
      echo 'Test command: emacs test.py --eval "(progn (lsp)(flycheck-verify-setup))"'
    '';
  };
in
{
  good = shell good-ref;
  bad = shell bad-ref;
  fixed = shell fixed-ref;
}
