#!/bin/bash

# random-notifs.sh
# Sends random notifications at random intervals (6–7 minutes)
# Designed for CachyOS + Sway + swaync
# - Respects swaync DND (no sound when DND is on)
# - Online: fetches fresh facts from API and saves to rolling cache
# - Offline: uses cache, falls back to built-in list

# Ensure only one instance runs at a time
LOCK_FILE="/tmp/random-notifs.lock"
if [[ -f "$LOCK_FILE" ]]; then
    OLD_PID=$(cat "$LOCK_FILE")
    if kill -0 "$OLD_PID" 2>/dev/null; then
        kill "$OLD_PID"
    fi
fi
echo $$ > "$LOCK_FILE"
trap "rm -f $LOCK_FILE" EXIT

CACHE_FILE="${XDG_DATA_HOME:-$HOME/.local/share}/random-notifs/cache.txt"
CACHE_MAX=500

mkdir -p "$(dirname "$CACHE_FILE")"

FALLBACK=(
    "🌊 The ocean covers about 71% of Earth's surface, yet over 80% of it remains unexplored."
    "🐝 Honey never spoils. Archaeologists found 3000-year-old honey in Egyptian tombs — still edible."
    "🌙 The Moon is slowly drifting away from Earth at about 3.8 cm per year."
    "🦈 Sharks are older than trees. They've existed for over 450 million years."
    "🧠 Your brain uses about 20% of your total energy despite being only 2% of your body weight."
    "🐙 Octopuses have three hearts and blue blood."
    "🌍 A day on Venus is longer than a year on Venus."
    "🦋 Butterflies taste with their feet."
    "🔥 Lightning strikes Earth about 100 times every second."
    "🐘 Elephants are the only animals that can't jump."
    "🌿 A group of flamingos is called a flamboyance."
    "🧊 Hot water can freeze faster than cold water under certain conditions. It's called the Mpemba effect."
    "🐦 A crow can recognize and remember human faces."
    "🪐 Saturn's rings are only about 10 meters thick on average."
    "🐌 A snail can sleep for 3 years."
    "🌺 The smell of rain has a name: petrichor."
    "🦑 The giant squid has the largest eyes of any living animal."
    "🧲 Every time you shuffle a deck of cards, that order has likely never existed before in history."
    "🌵 Cactus spines are actually modified leaves."
    "🐠 Clownfish can change sex. All clownfish are born male."
    "📺 The first TV remote was called the 'Lazy Bones'."
    "🍕 Pizza was first invented in Naples, Italy, in the 18th century."
    "🎮 The first video game ever created was 'Tennis for Two' in 1958."
    "✈️ A Boeing 747 has about 6 million parts."
    "🎵 'Happy Birthday' was the first song broadcast from space."
    "📚 The shortest war in history lasted only 38–45 minutes (Anglo-Zanzibar War, 1896)."
    "🏔️ Mount Everest grows about 4mm taller each year due to tectonic activity."
    "🦠 There are more bacterial cells in your body than human cells."
    "☕ Coffee is the second most traded commodity in the world after oil."
    "🍌 Bananas are technically berries. Strawberries are not."
    "🌑 There are more stars in the universe than grains of sand on Earth."
    "🐬 Dolphins have names for each other."
    "⏰ Quick reminder: stretch, look away from the screen, take a deep breath."
    "💧 Have you had enough water today? Hydration helps focus."
    "🚶 A short walk, even 5 minutes, can boost your mood and creativity."
    "🧘 Try the 4-7-8 breath: inhale 4s, hold 7s, exhale 8s."
    "👀 20-20-20 rule: every 20 min, look at something 20 feet away for 20 seconds."
    "😴 Sleep is when your brain consolidates memory. Don't skimp on it."
    "🤔 'The obstacle is the way.' — Marcus Aurelius"
    "💡 'An unexamined life is not worth living.' — Socrates"
    "🌱 'In the middle of difficulty lies opportunity.' — Einstein"
    "🌀 'We are what we repeatedly do. Excellence, then, is not an act, but a habit.' — Aristotle"
    "🧗 'It always seems impossible until it's done.' — Nelson Mandela"
    "🪞 'Be the change you wish to see in the world.' — Gandhi"
)

add_to_cache() {
    local fact="$1"
    if grep -qxF "$fact" "$CACHE_FILE" 2>/dev/null; then
        return
    fi
    echo "$fact" >> "$CACHE_FILE"
    local count
    count=$(wc -l < "$CACHE_FILE")
    if (( count > CACHE_MAX )); then
        tail -n "$CACHE_MAX" "$CACHE_FILE" > "${CACHE_FILE}.tmp" && mv "${CACHE_FILE}.tmp" "$CACHE_FILE"
    fi
}

fetch_online_fact() {
    local response fact
    response=$(curl -sf --max-time 5 "https://uselessfacts.jsph.pl/api/v2/facts/random?language=en")
    if [[ $? -eq 0 && -n "$response" ]]; then
        fact=$(echo "$response" | grep -o '"text":"[^"]*"' | sed 's/"text":"//;s/"$//')
        if [[ -n "$fact" ]]; then
            add_to_cache "$fact"
            echo "$fact"
            return 0
        fi
    fi
    return 1
}

get_cached_fact() {
    if [[ ! -s "$CACHE_FILE" ]]; then
        return 1
    fi
    local count
    count=$(wc -l < "$CACHE_FILE")
    local line=$(( RANDOM % count + 1 ))
    sed -n "${line}p" "$CACHE_FILE"
}

get_fallback_fact() {
    echo "${FALLBACK[$RANDOM % ${#FALLBACK[@]}]}"
}

get_fact() {
    local fact
    fact=$(fetch_online_fact) && { echo "$fact"; return; }
    fact=$(get_cached_fact) && { echo "$fact"; return; }
    get_fallback_fact
}

# Check if swaync DND is currently enabled
is_dnd_on() {
    swaync-client --get-dnd 2>/dev/null | grep -qi "true"
}

play_sound() {
    # Skip sound entirely if DND is on
    if is_dnd_on; then
        return
    fi
    local SOUND_PATHS=(
        "/usr/share/sounds/freedesktop/stereo/message.oga"
        "/usr/share/sounds/freedesktop/stereo/bell.oga"
        "/usr/share/sounds/Oxygen-Im-Message-In.ogg"
        "/usr/share/sounds/freedesktop/stereo/audio-volume-change.oga"
    )
    for sound in "${SOUND_PATHS[@]}"; do
        if [[ -f "$sound" ]]; then
            paplay "$sound" &
            break
        fi
    done
}

send_notification() {
    local msg
    msg=$(get_fact)
    play_sound
    notify-send "💬 Random Thought" "$msg" \
        --app-name="random-notifs" \
        --urgency=low \
        --expire-time=8000
}

# Wait for swaync to be ready on startup
sleep 30

while true; do
    send_notification
    # Sleep: 15 minutes (900 seconds)
    SLEEP_TIME=900
    sleep "$SLEEP_TIME"
done
