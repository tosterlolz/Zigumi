#!/usr/bin/env bash

# Prefer adding Limine as a git submodule (keeps repo tidy). Fall back to a shallow clone
# if submodule add fails or this isn't a git repository.
set -euo pipefail

REPO_URL="https://github.com/limine-bootloader/limine.git"
BRANCH="v10.x-binary"
DEST_DIR="limine"

if git rev-parse --git-dir >/dev/null 2>&1; then
	if [ -d "${DEST_DIR}" ]; then
		echo "${DEST_DIR} already exists; skipping submodule add/clone."
	else
		echo "Attempting to add Limine as a git submodule (branch ${BRANCH})..."
		# Use space-separated -b <branch> (some git versions don't like -b=branch)
		if git submodule add -b "${BRANCH}" --depth 1 "${REPO_URL}" "${DEST_DIR}" 2>&1 | tail -n 5; then
			echo "Limine added as submodule."
		else
			echo "submodule add failed, falling back to shallow clone..."
			git clone "${REPO_URL}" --branch="${BRANCH}" --depth=1 "${DEST_DIR}" 2>&1 | tail -n 5
			echo "Limine cloned."
		fi
	fi
else
	echo "Not a git repository; cloning Limine directly..."
	git clone "${REPO_URL}" --branch="${BRANCH}" --depth=1 "${DEST_DIR}" 2>&1 | tail -n 5
	echo "Limine cloned."
fi

echo "Done!"