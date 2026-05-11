#!/usr/bin/env fish

set -l GREEN (set_color green)
set -l RED (set_color red)
set -l RESET (set_color normal)

echo "$GREEN=== PipeWire Bluetooth Mic + Output Fix ===$RESET"
echo ""

read -P "Enter desired built-in mic volume (0-100) [35]: " VOLUME_INPUT

if test -z "$VOLUME_INPUT"
    set VOLUME 35
else if string match -r '^[0-9]+$' "$VOLUME_INPUT" &>/dev/null
    and test "$VOLUME_INPUT" -ge 0
    and test "$VOLUME_INPUT" -le 100
    set VOLUME "$VOLUME_INPUT"
else
    echo "$REDInvalid input! Using default 35.$RESET"
    set VOLUME 35
end

echo "→ Target mic volume: ${VOLUME}%"

mkdir -p ~/.config/wireplumber/wireplumber.conf.d

# Anti-hijack config
cat > ~/.config/wireplumber/wireplumber.conf.d/99-bluetooth-policy.conf << 'EOC'
wireplumber.settings = {
    bluetooth.autoswitch-to-headset-profile = false
}
EOC

# High quality output config
cat > ~/.config/wireplumber/wireplumber.conf.d/98-bluetooth-output.conf << 'EOC'
monitor.bluez.properties = {
    bluez5.roles = [ a2dp_sink a2dp_source ]
    bluez5.codecs = [ sbc sbc_xq aac ]
    bluez5.a2dp.ldac.quality = "hq"
}
EOC

echo "✅ Anti-hijack + High Quality A2DP config applied"

pactl set-default-source "alsa_input.pci-0000_00_1f.3.analog-stereo" 2>/dev/null; or true
wpctl set-volume @DEFAULT_AUDIO_SOURCE@ 0.$VOLUME --save

echo "🔄 Restarting PipeWire..."
systemctl --user restart pipewire pipewire-pulse wireplumber

sleep 2

echo "$GREEN🎉 All fixes applied successfully!$RESET"
echo "   → Built-in mic locked at ${VOLUME}%"
echo "   → Bluetooth earbuds output set to high quality (A2DP)"
echo ""
echo "Reconnect your Bluetooth audio device now for best results."
