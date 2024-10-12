import { Provider } from "../enums/registry";

export type ProfileDetails = {
  id: string;
  provider: Provider;
  balance: bigint;
  claimed: bigint;
};
