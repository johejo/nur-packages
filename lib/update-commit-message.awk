# Summarize literal version changes from a Git diff of pkgs/.
/^diff --git / {
    package = $3
    sub(/^a\/pkgs\//, "", package)
    sub(/\/.*/, "", package)
    if (!(package in seen)) {
        seen[package] = 1
        packages[++count] = package
    }
}

/^[-+][[:space:]]*version[[:space:]]*=[[:space:]]*"[^"$]+"[[:space:]]*;/ {
    version = $0
    sub(/^[^"]*"/, "", version)
    sub(/".*/, "", version)
    if (substr($0, 1, 1) == "-") {
        old[package] = version
    } else {
        new[package] = version
    }
}

function summary(package) {
    if (package in old && package in new && old[package] != new[package]) {
        return package ": update " old[package] " -> " new[package]
    }
    return package ": update package files"
}

END {
    if (count == 0) {
        exit 1
    }
    if (count == 1) {
        print summary(packages[1])
    } else {
        print "Update packages\n"
        for (i = 1; i <= count; i++) {
            print "- " summary(packages[i])
        }
    }
}
