# =============================================================================
# Fonts
# =============================================================================
#
# Fonts are core rather than per-profile because missing fonts look like a
# broken system rather than a different theme -- boxes instead of icons,
# unreadable menus.
# =============================================================================
{
  flake.nixosModules.coreFonts =
    { pkgs, ... }:
    {
      fonts = {
        packages = with pkgs; [
          # The icon font the noctalia bar draws its symbols with. Without it
          # the bar shows empty rectangles.
          material-symbols

          # Nerd Font symbols, used by starship prompts and terminal tools.
          nerd-fonts.symbols-only
          nerd-fonts.jetbrains-mono

          # General text, including non-Latin scripts and colour emoji.
          noto-fonts
          noto-fonts-cjk-sans
          noto-fonts-color-emoji
        ];

        fontconfig = {
          enable = true;

          # Fall back to Nerd Font symbols first (so icons resolve everywhere)
          # and colour emoji last.
          defaultFonts = {
            monospace = [ "JetBrainsMono Nerd Font" "Symbols Nerd Font" ];
            sansSerif = [ "Noto Sans" "Symbols Nerd Font" ];
            serif = [ "Noto Serif" "Symbols Nerd Font" ];
            emoji = [ "Noto Color Emoji" ];
          };
        };
      };
    };
}
