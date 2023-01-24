import { types as T, matches } from "../deps.ts";

const { shape, arrayOf, string, boolean } = matches;

const matchBitcoindConfig = shape({
  rpc: shape({
    enable: boolean,
  }),
  advanced: shape({
    pruning: shape({
      mode: string,
    }),
  }),
});

const matchProxyConfig = shape({
  users: arrayOf(
    shape(
      {
        name: string,
        "allowed-calls": arrayOf(string),
        password: string,
        "fetch-blocks": boolean,
      },
      ["fetch-blocks"],
    ),
  ),
});

function times<T>(fn: (i: number) => T, amount: number): T[] {
  const answer = new Array(amount);
  for (let i = 0; i < amount; i++) {
    answer[i] = fn(i);
  }
  return answer;
}

function randomItemString(input: string) {
  return input[Math.floor(Math.random() * input.length)];
}

const serviceName = "specter";
const fullChars =
  "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";

type Check = {
  currentError(config: T.Config): string | void;
  fix(config: T.Config): void;
};

const checks: Array<Check> = [
  {
    currentError(config) {
      if (!matchProxyConfig.test(config)) {
        return "Config is not the correct shape";
      }
      if (config.users.some((x) => x.name === serviceName)) {
        return;
      }
      return `Must have an RPC user named "${serviceName}"`;
    },
    fix(config) {
      if (!matchProxyConfig.test(config)) {
        return;
      }
      config.users.push({
        name: serviceName,
        "allowed-calls": [],
        password: times(() => randomItemString(fullChars), 22).join(""),
      });
    },
  },
  ...[
    "getindexinfo",
    "getblockcount",
    "getchaintips",
    "getmempoolinfo",
    "getblockchaininfo",
    "getblockhash",
    "getblock",
    "getmempoolentry",
    "getrawtransaction",
    "getrawmempool",
    "gettxout",
    "validateaddress",
    "estimatesmartfee",
    "getbestblockhash",
    "getblockheader",
    "getinfo",
    "getmempoolinfo",
    "getnetworkinfo",
    "getpeerinfo",
    "getrawtransaction",
    "sendrawtransaction",
    "uptime",
    "scantxoutset",
    "listwallets",
    "getblockfilter",
    "listwalletdir",
    "createwallet",
    "gettxoutsetinfo",
    "importdescriptors",
    "listlabels",
    "getwalletinfo",
    "listtransactions",
    "getbalances",
    "listlockunspent",
    "getreceivedbyaddress",
    "listsinceblock",
    "rescanblockchain",
    "loadwallet",
    "gettransaction",
    "walletprocesspsbt",
    "setlabel",
    "walletcreatefundedpsbt",
    "listunspent",
    "getmininginfo",
    "abortrescan",
    "unloadwallet",
    "combinepsbt",
    "finalizepsbt",
    "testmempoolaccept",
    "lockunspent",
    "gettxoutproof",
    "converttopsbt",
    "utxoupdatepsbt",
    "importmulti",
    "getaddressesbylabel",
  ].map(
    (operator): Check => ({
      currentError(config) {
        if (!matchProxyConfig.test(config)) {
          return "Config is not the correct shape";
        }
        if (
          config.users.find((x) => x.name === serviceName)?.["allowed-calls"]
            ?.some((x) => x === operator) ?? false
        ) {
          return;
        }
        return `RPC user "c-lightning" must have "${operator}" enabled`;
      },
      fix(config) {
        if (!matchProxyConfig.test(config)) {
          throw new Error("Config is not the correct shape");
        }
        const found = config.users.find((x) => x.name === serviceName);
        if (!found) {
          throw new Error("Users for c-lightning should exist");
        }
        found["allowed-calls"] = [...(found["allowed-calls"] ?? []), operator];
      },
    }),
  ),
];

export const dependencies: T.ExpectedExports.dependencies = {
  bitcoind: {
    // deno-lint-ignore require-await
    async check(effects, configInput) {
      effects.info("check bitcoind");
      const config = configInput as any; //matchBitcoindConfig.unsafeCast(configInput);
      if (!config.rpc.enable) {
        return { error: "Must have RPC enabled" };
      }
      if (config.advanced.pruning.mode !== "disabled") {
        return { error: "Pruning must be disabled (must be an archival node)" };
      }
      if (!config.advanced.blockfilters.blockfilterindex) {
        return {
          error:
            "Must have block filter index enabled for Run The Numbers to work",
        };
      }
      if (config.rpc.advanced.threads < 4) {
        return { error: "Must be greater than or equal to 4" };
      }
      return { result: null };
    },
    // deno-lint-ignore require-await
    async autoConfigure(effects, configInput) {
      effects.info("autoconfigure bitcoind");
      const config = configInput as any; //matchBitcoindConfig.unsafeCast(configInput);
      config.rpc.enable = true;
      config.advanced.blockfilters.blockfilterindex = true;
      if (config.rpc.advanced.threads < 4) {
        config.rpc.advanced.threads = 4;
      }
      if (config.advanced.pruning.mode !== "disabled") {
        config.advanced.pruning.mode = "disabled";
      }
      return { result: config };
    },
  },
  "btc-rpc-proxy": {
    // deno-lint-ignore require-await
    async check(effects, configInput) {
      effects.info("check btc-rpc-proxy");
      for (const checker of checks) {
        const error = checker.currentError(configInput);
        if (error) {
          effects.error(`throwing error: ${error}`);
          return { error };
        }
      }
      return { result: null };
    },
    // deno-lint-ignore require-await
    async autoConfigure(effects, configInput) {
      effects.info("autoconfigure btc-rpc-proxy");
      for (const checker of checks) {
        const error = checker.currentError(configInput);
        if (error) {
          checker.fix(configInput);
        }
      }
      return { result: configInput };
    },
  },
};
