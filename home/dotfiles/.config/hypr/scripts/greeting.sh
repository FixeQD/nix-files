#!/bin/bash

early_morning_greetings=(
    "hej, wcześnie wstajesz 👀"
    "świt? serio?"
    "caffeine level: critical"
    "no sleep, just bugs"
    "o tej porze tylko ptaki i devowie"
    "morning.exe uruchamianie..."
    "świat jeszcze śpi, ty szponcisz"
    "5 rano, szanuję ten cringe"
    "kto tak wcześnie szponci kod?"
    "nocna zmiana się nie skończyła?"
)

weekend_early_morning_greetings=(
    "weekend i już wstałeś? 💀"
    "o tej porze? w weekend? skill issue"
    "słońce wstało, ty też, po co?"
    "to nie jest normalne zachowanie"
    "hej nocna zmiano, czas spać"
    "weekend a ty szponcisz o świcie 💀"
)

morning_greetings=(
    "rise and grind ☀️"
    "kawa sama się nie zrobi ☕"
    "nowy dzień, nowe bugi"
    "commit coś dzisiaj"
    "dzień dobry, sługo kapitału"
    "git checkout -b nowy-dzień"
    "kolejny dzień, kolejny segfault"
    "standup za chwilę, powodzenia"
    "SO już otwarty?"
    "dzisiaj zero bugów... haha jk"
    "print('dzień dobry')"
    "uptime: 0h, jeszcze się da"
    "dzień dobry świecie undefined"
    "no cap, da się przeżyć"
    "szponcisz już od rana? slay"
    "poranny szpont, klasyk"
)

weekend_morning_greetings=(
    "weekend, możesz żyć 😴"
    "zero standupów, full vibe"
    "jeszcze 5 minut... klasyk"
    "side project się sam nie napisze"
    "lazy sunday ale z kompilatorem"
    "wolne = szponcisz co chcesz"
    "socialife.exe not found"
    "śpisz czy udajesz?"
    "weekendowy szpont, respekt"
)

midday_greetings=(
    "lunch był? nie? skill issue"
    "południe, czas na kryzys"
    "git blame, ale na siebie"
    "build: failed (jak zwykle)"
    "to nie bug, to feature"
    "refactor czy nowe feature? oba złe"
    "połowa dnia, połowa sanity"
    "zjedz coś na litość boską"
    "12:00 — czas na kolejną kawę"
    "produktywność: 404"
    "szponcisz od rana i dalej nic? mood"
    "południowy kryzys szpontowy"
)

weekend_midday_greetings=(
    "południe w piżamie, klasyk"
    "brunch czy od razu obiad?"
    "połowa weekendu za nami 😔"
    "zjedz coś człowieku"
    "git pull origin weekend"
    "szponcisz w południe w weekend? no cap respekt"
)

afternoon_greetings=(
    "deadline? jaki deadline?"
    "jeszcze trochę i fajrant"
    "SO tab numer 47 i counting"
    "merge conflict? kondolencje"
    "popołudniowy kryzys, normalka"
    "nic nie działa i nikt nie wie czemu"
    "vim otwarty, wyjścia brak"
    "to się samo nie zdeployuje"
    "stack trace 200 linii, normalka"
    "nadal szponcisz? gigachad"
    "popołudniowy szpont, to już choroba"
    "szpont nie czeka na fajrant"
)

weekend_afternoon_greetings=(
    "weekend w toku 😎"
    "dotknąłeś dziś trawy?"
    "skill issue czy skill issue?"
    "refactor w sobotę? slay"
    "wyjdź na zewnątrz... albo nie"
    "weekend = weekday bez spotkań"
    "szponcisz w weekend? no cap"
)

early_evening_greetings=(
    "fajrant dla normalnych ludzi"
    "dzień przeżyty, commit wypchnięty"
    "push zrobiłeś? możesz żyć"
    "touchgrass.exe — ostatnia szansa"
    "system działa? nie ruszaj"
    "wychodzisz dziś? nie? respekt"
    "kolacja > kolejny szpont, serio"
    "wieczorny szpont się zaczyna?"
)

evening_greetings=(
    "wieczorny lo-fi i zimna kawa, meta"
    "netflix czy kolejny PR?"
    "wieczorny debug session klasyk"
    "dziś było git? 🌆"
    "jeszcze jeden feature i idę spać, kłamstwo"
    "czas na chill"
    "dark mode aktywny, tryb nocny też"
    "wieczorny szpont to najlepszy szpont"
    "szponcisz przy świecach? romantic"
)

late_evening_greetings=(
    "jeszcze żyjesz?"
    "jeszcze jeden odcinek 🤡"
    "godzina złych decyzji"
    "jutrzejszy ty się tym zajmie"
    "ostatni commit dnia? kłamstwo"
    "nikt normalny o tej porze... więc git"
    "main branch o północy, odważnie"
    "ten bug poczeka do rana"
    "SO też nie śpi, jesteście razem"
    "nocny szpont, klasyczna forma"
    "szponcisz o tej porze? 💀"
)

night_greetings=(
    "idź spać"
    "sudo shutdown -h now"
    "sleep(8 * 3600)"
    "null pointer w głowie, dobranoc"
    "zamknij laptopa. nie pytam."
    "jutro będziesz trupem 💀"
    "garbage collector czeka na twój mózg"
    "o tej porze tylko bugi się rodzą"
    "git commit -m 'goodnight'"
    "4 rano? sigma ale idź spać"
    "system needs reboot"
    "zostaw ten szpont na jutro"
    "mózg.exe przestał odpowiadać"
)

_last_greeting=""

get_greeting() {
    local hour weekday is_weekend greetings msg
    hour=$(date +"%H")
    weekday=$(date +%u)
    (( weekday >= 6 )) && is_weekend=1 || is_weekend=0

    if (( hour >= 5 && hour < 8 )); then
        (( is_weekend )) \
            && greetings=("${weekend_early_morning_greetings[@]}") \
            || greetings=("${early_morning_greetings[@]}")
    elif (( hour >= 8 && hour < 12 )); then
        (( is_weekend )) \
            && greetings=("${weekend_morning_greetings[@]}") \
            || greetings=("${morning_greetings[@]}")
    elif (( hour >= 12 && hour < 14 )); then
        (( is_weekend )) \
            && greetings=("${weekend_midday_greetings[@]}") \
            || greetings=("${midday_greetings[@]}")
    elif (( hour >= 14 && hour < 18 )); then
        (( is_weekend )) \
            && greetings=("${weekend_afternoon_greetings[@]}") \
            || greetings=("${afternoon_greetings[@]}")
    elif (( hour >= 18 && hour < 20 )); then
        greetings=("${early_evening_greetings[@]}")
    elif (( hour >= 20 && hour < 22 )); then
        greetings=("${evening_greetings[@]}")
    elif (( hour >= 22 )); then
        greetings=("${late_evening_greetings[@]}")
    else
        greetings=("${night_greetings[@]}")
    fi

    local attempts=0
    while (( attempts < 10 )); do
        msg="${greetings[$RANDOM % ${#greetings[@]}]}"
        [[ "$msg" != "$_last_greeting" ]] && break
        (( attempts++ ))
    done

    _last_greeting="$msg"
    echo "$msg"
}

get_alerts() {
    local -a alerts

    local load load_int
    load=$(cut -d " " -f1 /proc/loadavg)
    load_int=${load%.*}
    (( load_int >= 6 )) && alerts+=("CPU się gotuje 🔥 load: $load")
    (( load_int >= 3 && load_int < 6 )) && alerts+=("coś szponcisz... load: $load")

    local mem_used
    mem_used=$(free | awk '/Mem:/ {print int($3/$2 * 100)}')
    (( mem_used >= 90 )) && alerts+=("RAM na oparach (${mem_used}%) 💀")
    (( mem_used >= 75 && mem_used < 90 )) && alerts+=("RAM ciężko oddycha (${mem_used}%)")

    if [[ -f /sys/class/power_supply/BAT0/capacity ]]; then
        local battery
        battery=$(cat /sys/class/power_supply/BAT0/capacity)
        (( battery <= 15 )) && alerts+=("zaraz zdechniesz 🔋 ${battery}%")
        (( battery > 15 && battery <= 30 )) && alerts+=("low battery (${battery}%)")
    fi

    (( ${#alerts[@]} > 0 )) && printf '%s\n' "${alerts[@]}"
}

render() {
    local -a alerts
    mapfile -t alerts < <(get_alerts)

    if (( ${#alerts[@]} > 0 )); then
        echo "${alerts[$RANDOM % ${#alerts[@]}]}"
    else
        get_greeting
    fi
}

sleep_to_next_minute() {
    local secs=$(( 10#$(date +%S) ))
    sleep $(( 60 - secs ))
}

render
