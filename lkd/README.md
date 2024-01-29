Build fast-data-dev:

    docker build -t lensesio/fast-data-dev:local .

Build compile-lkd:

    docker build --target compile-lkd -t lensesio/lkd:local .

Get LKD archive:

    mkdir build
    docker run -rm -it -v $PWD/build:/mnt lensesio/lkd:local
