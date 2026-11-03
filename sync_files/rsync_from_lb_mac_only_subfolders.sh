#!/bin/bash
## author: zhaoyafei0210@gmail.com

# rsync --progress -aEh $1 $2

  # --include='*.'* \      # 包含所有带扩展名的文件（根据实际情况调整）

#!/bin/bash
## author: zhaoyafei0210@gmail.com

# rsync --progress -aEh $1 $2

# rsync --progress -a \
#   --existing \  # 只考虑已有文件
#   --include='*/' \  # 包含所有子目录
#   --include='*/*' \ # 包含所有子目录下的文件
#   --exclude='*/.*' \ # 排除所有隐藏文件（以点开头的文件）
#   --exclude='*.crdownload' \ # 排除所有 Chrome 下载中的临时文件
#   ~/lb/ zyf-mbp-m3:/Users/admin/Downloads/ # 不要遗漏结尾的"/"


rsync --progress -a \
  --timeout=300 \
  --inplace --partial \
  --include='*/' \
  --include='*/*' \
  --exclude='*/.*' \
  --exclude='*.crdownload' \
  zyf-mbp-m3:/Users/admin/Downloads/ ~/lb/ # 不要遗漏结尾的"/"