<h1 align='center'>Stausi Billing</h1>

A reworked version of esx_billing.

Please use this table change, for your esx_billing

```sql
ALTER TABLE `billing`
ADD COLUMN `time` int(11) NOT NULL DEFAULT unix_timestamp();
```

## Setup Locales 
1 Download [Ox-Lib](https://github.com/overextended/ox_lib/releases)
2 Go to your server.cfg and add setr 
``` lua 
ox:locale dk 
```
or change it to your preferred language.

## Installing modules

1. Install [pnpm](https://pnpm.io/installation)
2. CD to the `web` folder and run `pnpm i`, wait for it to complete.

## Developing the App

1. Run `pnpm dev`
2. Open [http://localhost:3000](http://localhost:3000) in your browser to view the app.

## Building the App

1. Run `pnpm build` to build the app.