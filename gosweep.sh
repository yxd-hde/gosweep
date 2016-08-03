#!/bin/bash
# The script does automatic checking on a Go package and its sub-packages, including:
# 1. gofmt         (http://golang.org/cmd/gofmt/)
# 2. goimports     (https://github.com/bradfitz/goimports)
# 3. golint        (https://github.com/golang/lint)
# 4. go vet        (http://golang.org/cmd/vet)
# 5. ineffassign   (https://github.com/gordonklaus/ineffassign)
# 6. race detector (http://blog.golang.org/race-detector)
# 7. test coverage (http://blog.golang.org/cover)

set -e

# Automatic checks
test -z "$(gofmt -l -w .     | tee /dev/stderr)"
test -z "$(goimports -l -w . | tee /dev/stderr)"
#test -z "$(golint .          | tee /dev/stderr)"
test -z "$(ineffassign .     | tee /dev/stderr)"

DIR_SOURCE="$(find . -maxdepth 10 -type f -not -path '*/vendor*' -name '*.go' | xargs -I {} dirname {} | sort | uniq)"

go vet ${DIR_SOURCE}
#env GORACE="halt_on_error=0" go test -short -race ${DIR_SOURCE}


for dir in ${DIR_SOURCE};
do
    ineffassign $dir
done


# Run test coverage on each subdirectories and merge the coverage profile.

echo "mode: count" > profile.cov

for dir in ${DIR_SOURCE};
do
    go test -covermode=count -coverprofile=$dir/profile.tmp $dir
    if [ -f $dir/profile.tmp ]
    then
        cat $dir/profile.tmp | tail -n +2 >> profile.cov
        rm $dir/profile.tmp
    fi
done

go tool cover -html=profile.cov -o coverage.html
