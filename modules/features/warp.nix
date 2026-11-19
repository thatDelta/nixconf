# =============================================================================
# Cloudflare WARP  --  whole-system VPN that Cloudflare-protected sites trust
# =============================================================================
#
# WHY THIS AS WELL AS PSIPHON
#   Psiphon exits through shared datacenter IPs (DigitalOcean, IONOS), which
#   Cloudflare's bot protection flags -> "Sorry, you have been blocked" on
#   reddit, chatgpt and friends. WARP traffic comes out of Cloudflare's OWN
#   network, so those sites let it through.
#
# WHAT IT HIDES, AND WHAT IT DOESN'T
#   - Your ISP / the local Wi-Fi sees only encrypted traffic to Cloudflare.
#   - Websites see a Cloudflare IP, not yours.
#   - BUT it keeps you in your own country/region (sites still see roughly
#     where you are), and Cloudflare itself can see your real address.
#   - Some networks block WARP outright; that is what Psiphon is for.
#   Use one at a time -- both want to own all routing.
#
# HOW TO USE IT
#   The cloud icon in the bar's tray (warp-taskbar) -- click to connect.
#   Or in a terminal:
#     warp-cli registration new     once, the first time
#     warp-cli connect | disconnect | status
#     warp-cli mode warp            full VPN (default)
#     curl https://www.cloudflare.com/cdn-cgi/trace   look for warp=on
# =============================================================================
{ ... }:
{
  flake.nixosModules.warp =
    { config, ... }:
    {
      # warp-svc (the daemon, root) + warp-cli.
      services.cloudflare-warp.enable = true;

      # The tray app ships as a user unit inside the package, but the nixpkgs
      # module never installs or starts it. Do both, with the desktop session.
      systemd.packages = [ config.services.cloudflare-warp.package ];
      systemd.user.services.warp-taskbar.wantedBy = [ "graphical-session.target" ];
    };
}
