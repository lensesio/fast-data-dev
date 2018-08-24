# Lenses Box with ACLs

An example of the Lenses Dev Box setup with SSL and ACLs.

## Usage

Edit `docker-compose.yml` to add your developer license link to the `EULA`
_environment variable_. Like this:

    - EULA=https://dl.lenses.stream/d/?id=<YOUR-LICENSE-KEY>

Then just run _docker-compose_. After a minute or so, Lenses should be available
at <http://localhost:3030>.

    docker-compose up

For your clients, you will find some SSL keystores and truststore
under <http://localhost:3030/fdd/certs>.

## Sample Data

By default we disable the built-in data generators because, the principal
builder class can become too vocal as the generators use the PLAINTEXT listener
of the brokers. Feel free to enable it by setting `SAMPLEDATA` to `1` in the
`docker-compose.yml`.

## landoop/fast-data-dev

It should be straightforward to adjust the example for `landoop/fast-data-dev`,
just change the image name in `docker-compose.yml`.  You can also drop the
Lenses settings from there as well, though they are ignored from
_fast-data-dev_, so it ins't necessary.
