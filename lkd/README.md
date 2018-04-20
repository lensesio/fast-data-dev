Build fast-data-dev:

    docker build -t landoop/fast-data-dev .

Build compile-lkd:

    docker build --target compile-lkd -t landoop/lkd/lkd .

Get LKD archive:

    mkdir build
    docker run -rm -it -v $PWD/build:/mnt landoop/lkd/lkd
