youtube-dl ^
    --verbose ^
    --skip-unavailable-fragments^
    --write-description ^
    --write-info-json ^
    --write-annotations ^
    --write-sub ^
    --write-thumbnail  ^
    --format "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best" ^
    --id ^
    --recode-video mp4 ^
    --prefer-ffmpeg ^
    --batch-file ^
    %1