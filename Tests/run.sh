#!/bin/bash
set -euo pipefail

project_root="$(cd "$(dirname "$0")/.." && pwd)"
test_build="$(mktemp -d "${TMPDIR:-/tmp}/NotesRegression.XXXXXX")"
trap 'rm -rf "$test_build"' EXIT
cd "$project_root"
developer_dir="$(xcode-select -p)"
sdk_path="$developer_dir/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk"
swift_compiler="$developer_dir/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc"

"$swift_compiler" -swift-version 5 -parse-as-library -sdk "$sdk_path" \
    -module-cache-path "$test_build/ModuleCache" \
    Notes/Services/Persistence/JSONFileStorage.swift \
    Notes/Features/Notes/Models/Note.swift \
    Notes/Features/Notes/Stores/NotesStore.swift \
    Notes/Features/Notes/Presentation/NoteEditorModel.swift \
    Notes/Features/Notes/Presentation/NoteFormatting.swift \
    Notes/Features/Schedule/Models/ScheduleItem.swift \
    Notes/Features/Schedule/Models/InferredScheduleChange.swift \
    Notes/Features/Schedule/Models/ScheduleDayGroup.swift \
    Notes/Features/Schedule/Stores/ScheduleStore.swift \
    Notes/Features/Schedule/Presentation/ScheduleEditorModel.swift \
    Notes/Features/Schedule/Presentation/ScheduleFormatting.swift \
    Notes/Services/ScheduleExtraction/ExtractedSchedule.swift \
    Notes/Services/ScheduleExtraction/ScheduleExtracting.swift \
    Notes/Services/ScheduleExtraction/ScheduleIntentDetector.swift \
    Notes/Services/ScheduleExtraction/DeepSeek/*.swift \
    Notes/App/Workflows/NoteCaptureCoordinator.swift \
    Notes/App/Presentation/ToastPresenter.swift \
    Tests/ArchitectureRegression.swift \
    -o "$test_build/ArchitectureRegression"
"$test_build/ArchitectureRegression"
