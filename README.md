![deploy-to-cloud](https://github.com/russorat/influxdb-gitops/workflows/deploy-to-cloud/badge.svg)

This repo will contain a set of scripts for working with influxdb systems.


To load everything, just run the install script. The `env` param refers to the `influx config` profile in the cli and defaults to `default`.
```
chmod +x install.sh
./install.sh [env]
```

Once you run the install script, you can start loading data with the `start_telegraf.sh`, which also accepts the `env` parameter. You will need to make sure Telegraf is in your path before running this using something like `brew install telegraf`.
```
chmod +x start_telegraf.sh
./start_telegraf.sh [env]
```

