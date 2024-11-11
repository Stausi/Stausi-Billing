<h1 align='center'>Stausi Billing</h1>

A reworked version of esx_billing.

Please use this table change, for your esx_billing

```sql
ALTER TABLE `billing`
ADD COLUMN `time` int(11) NOT NULL DEFAULT unix_timestamp();
```

## Installing modules

1. Install [node.js](https://nodejs.org/en/download)
2. CD to the `web` folder and run `npm i`, wait for it to complete.

## Developing the app

1. Run `npm dev`
2. Go to `http://localhost:3000` in your browser to see the app in your browser.

## Building the app

1. Run `npm run build` to build the app.