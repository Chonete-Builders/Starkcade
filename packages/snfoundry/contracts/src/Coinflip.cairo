use starknet::{ContractAddress};
#[starknet::interface]
pub trait ICoinflip<TContractState> {
    // * Read functions
    fn get_contract_balance(self: @TContractState) -> u256;
    fn get_leaderboard(self: @TContractState) -> Array<(ContractAddress, u256)>;
    fn get_recent_flips(self: @TContractState) -> Array<(ContractAddress, bool, u256)>;
    fn get_user_flips(self: @TContractState, user: ContractAddress) -> Array<(bool, u256)>;
    fn get_min_bet(self: @TContractState) -> u256;
    fn get_max_bet(self: @TContractState) -> u256;
    fn get_house_edge(self: @TContractState) -> u256;
    fn get_pending_bet(self: @TContractState, user: ContractAddress) -> (bool, u256);

    // * Write functions
    fn play(ref self: TContractState, selected_result: bool) -> bool;
    fn place_bet(ref self: TContractState, selected_result: bool, amount: u256);
    fn flip_coin(ref self: TContractState) -> bool;
    fn withdraw(ref self: TContractState, amount: u256);
    fn set_min_bet(ref self: TContractState, amount: u256);
    fn set_max_bet(ref self: TContractState, amount: u256);
    fn set_house_edge(ref self: TContractState, new_edge: u256);
}

#[starknet::contract]
pub mod Coinflip {
    use core::array::ArrayTrait;
    use core::hash::{HashStateTrait, HashStateExTrait};
    use core::pedersen::PedersenTrait;
    use openzeppelin_access::ownable::OwnableComponent;
    use openzeppelin_token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
    use starknet::storage::{
        StorageMapReadAccess, StoragePointerReadAccess, StoragePointerWriteAccess,
        StorageMapWriteAccess, Map, Vec, VecTrait, StoragePathEntry, MutableVecTrait
    };
    use starknet::{
        ContractAddress, get_block_timestamp, get_caller_address, get_contract_address,
        contract_address::contract_address_const
    };

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    // * Constants
    const MAX_LEADERBOARD_SIZE: u8 = 10;
    const MAX_RECENT_FLIPS: usize = 10;
    // * Default to 5% house edge (500 = 5.00%)
    const DEFAULT_HOUSE_EDGE: u256 = 500;
    const PERCENTAGE_BASE: u256 = 10000; // Base for percentage calculations

    // STRK Token address - Should be changed for different networks
    pub fn STRK_ADDRESS() -> ContractAddress {
        contract_address_const::<
            0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
        >()
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        BetPlaced: BetPlaced,
        CoinFlipped: CoinFlipped,
        GamePlayed: GamePlayed,
        ConfigUpdated: ConfigUpdated,
    }

    #[derive(Drop, starknet::Event)]
    struct BetPlaced {
        #[key]
        user: ContractAddress,
        selected_result: bool,
        amount: u256,
        timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    struct CoinFlipped {
        #[key]
        user: ContractAddress,
        outcome: bool,
        won: bool,
        amount: u256,
        payout: u256,
        timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    struct GamePlayed {
        #[key]
        user: ContractAddress,
        selected_result: bool,
        outcome: bool,
        amount: u256,
        payout: u256,
        timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    struct ConfigUpdated {
        min_bet: u256,
        max_bet: u256,
        house_edge: u256,
        timestamp: u64,
    }

    #[storage]
    struct Storage {
        min_bet: u256,
        max_bet: u256,
        house_edge: u256,
        bets: Map<ContractAddress, u256>,
        selected_results: Map<ContractAddress, bool>,
        leaderboard: Map<u8, (ContractAddress, u256)>,
        recent_flips: Vec<(ContractAddress, bool, u256)>,
        user_flips: Map<ContractAddress, Vec<(bool, u256)>>,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress, min_bet: u256, max_bet: u256) {
        self.ownable.initializer(owner);
        self.min_bet.write(min_bet);
        self.max_bet.write(max_bet);
        self.house_edge.write(DEFAULT_HOUSE_EDGE);
    }

    #[abi(embed_v0)]
    impl CoinflipImpl of super::ICoinflip<ContractState> {
        // View functions
        fn get_contract_balance(self: @ContractState) -> u256 {
            IERC20Dispatcher { contract_address: STRK_ADDRESS() }.balance_of(get_contract_address())
        }

        fn get_leaderboard(self: @ContractState) -> Array<(ContractAddress, u256)> {
            let mut leaderboard = ArrayTrait::new();
            let mut i: u8 = 1;
            loop {
                if i > MAX_LEADERBOARD_SIZE {
                    break;
                }
                leaderboard.append(self.leaderboard.read(i));
                i += 1;
            };
            leaderboard
        }

        fn get_recent_flips(self: @ContractState) -> Array<(ContractAddress, bool, u256)> {
            let mut recent_flips_array = ArrayTrait::new();
            let len = self.recent_flips.len();
            for i in 0..len {
                recent_flips_array.append(self.recent_flips.at(i).read());
            };
            recent_flips_array
        }

        fn get_user_flips(self: @ContractState, user: ContractAddress) -> Array<(bool, u256)> {
            let mut user_flips_array = ArrayTrait::new();
            let len = self.user_flips.entry(user).len();
            for i in 0..len {
                user_flips_array.append(self.user_flips.entry(user).at(i).read());
            };
            user_flips_array
        }

        fn get_min_bet(self: @ContractState) -> u256 {
            self.min_bet.read()
        }

        fn get_max_bet(self: @ContractState) -> u256 {
            self.max_bet.read()
        }

        fn get_house_edge(self: @ContractState) -> u256 {
            self.house_edge.read()
        }

        fn get_pending_bet(self: @ContractState, user: ContractAddress) -> (bool, u256) {
            (self.selected_results.read(user), self.bets.read(user))
        }

        // External functions
        fn play(ref self: ContractState, selected_result: bool) -> bool {
            let caller = get_caller_address();
            // Standard bet of 0.05 STRK
            let amount: u256 = 50000000000000000_u256;

            self.place_bet(selected_result, amount);
            let outcome = self.flip_coin();

            // Emit combined event
            self
                .emit(
                    GamePlayed {
                        user: caller,
                        selected_result,
                        outcome,
                        amount,
                        payout: if outcome == selected_result {
                            self._calculate_payout(amount)
                        } else {
                            0
                        },
                        timestamp: get_block_timestamp(),
                    },
                );

            outcome
        }

        fn place_bet(ref self: ContractState, selected_result: bool, amount: u256) {
            let caller = get_caller_address();

            // Validation
            assert(amount >= self.min_bet.read(), 'Bet too small');
            assert(amount <= self.max_bet.read(), 'Bet too large');
            assert(self.bets.read(caller) == 0, 'Pending bet exists');

            // Transfer tokens
            let token = IERC20Dispatcher { contract_address: STRK_ADDRESS() };
            token.transfer_from(caller, get_contract_address(), amount);

            // Store bet
            self.bets.write(caller, amount);
            self.selected_results.write(caller, selected_result);

            // Update leaderboard
            self._update_leaderboard(caller, amount);

            self
                .emit(
                    BetPlaced {
                        user: caller, selected_result, amount, timestamp: get_block_timestamp(),
                    },
                );
        }

        fn flip_coin(ref self: ContractState) -> bool {
            let caller = get_caller_address();

            // Validate bet exists
            let bet_amount = self.bets.read(caller);
            assert(bet_amount > 0, 'No pending bet');

            let selected_result = self.selected_results.read(caller);

            // Generate outcome using block hash
            let outcome = self._generate_outcome();
            let won = outcome == selected_result;

            // Process payout
            if won {
                let payout = self._calculate_payout(bet_amount);
                IERC20Dispatcher { contract_address: STRK_ADDRESS() }.transfer(caller, payout);
            }

            // Clear bet
            self.bets.write(caller, 0);
            self.selected_results.write(caller, false);

            // Update history
            self._update_recent_flips(caller, outcome, bet_amount);
            self._update_user_flips(caller, outcome, bet_amount);

            self
                .emit(
                    CoinFlipped {
                        user: caller,
                        outcome,
                        won,
                        amount: bet_amount,
                        payout: if won {
                            self._calculate_payout(bet_amount)
                        } else {
                            0
                        },
                        timestamp: get_block_timestamp(),
                    },
                );

            outcome
        }

        fn withdraw(ref self: ContractState, amount: u256) {
            self.ownable.assert_only_owner();
            let token = IERC20Dispatcher { contract_address: STRK_ADDRESS() };
            let balance = token.balance_of(get_contract_address());
            assert(amount <= balance, 'Insufficient balance');
            token.transfer(self.ownable.owner(), amount);
        }

        fn set_min_bet(ref self: ContractState, amount: u256) {
            self.ownable.assert_only_owner();
            assert(amount <= self.max_bet.read(), 'Min bet > max bet');
            self.min_bet.write(amount);
            self._emit_config_update();
        }

        fn set_max_bet(ref self: ContractState, amount: u256) {
            self.ownable.assert_only_owner();
            assert(amount >= self.min_bet.read(), 'Max bet < min bet');
            self.max_bet.write(amount);
            self._emit_config_update();
        }

        fn set_house_edge(ref self: ContractState, new_edge: u256) {
            self.ownable.assert_only_owner();
            assert(new_edge <= 1000_u256, 'House edge too high'); // Max 10%
            self.house_edge.write(new_edge);
            self._emit_config_update();
        }
    }

    #[generate_trait]
    impl InternalFunctions of InternalFunctionsTrait {
        fn _calculate_payout(self: @ContractState, bet_amount: u256) -> u256 {
            let house_edge = self.house_edge.read();
            bet_amount + (bet_amount * (PERCENTAGE_BASE - house_edge) / PERCENTAGE_BASE)
        }

        fn _generate_outcome(self: @ContractState) -> bool {
            let timestamp = get_block_timestamp();

            let output = PedersenTrait::new(0).update_with(timestamp).finalize();
            let random_value: u256 = output.into();
            (random_value % 2) == 0
        }

        fn _update_leaderboard(ref self: ContractState, user: ContractAddress, amount: u256) {
            let mut current_position: u8 = 1;
            loop {
                if current_position > MAX_LEADERBOARD_SIZE {
                    break;
                }
                let (_current_user, current_amount) = self.leaderboard.read(current_position);
                if amount > current_amount {
                    // Shift existing entries down
                    let mut shift_position = MAX_LEADERBOARD_SIZE;
                    loop {
                        if shift_position <= current_position {
                            break;
                        }
                        let previous = self.leaderboard.read(shift_position - 1);
                        self.leaderboard.write(shift_position, previous);
                        shift_position -= 1;
                    };
                    // Insert new entry
                    self.leaderboard.write(current_position, (user, amount));
                    break;
                }
                current_position += 1;
            };
        }


        fn _update_recent_flips(
            ref self: ContractState, user: ContractAddress, outcome: bool, amount: u256
        ) {
            // Copy the stored vector into a memory array
            let mut flips = self.get_recent_flips();

            if flips.len() >= MAX_RECENT_FLIPS {
                let mut new_flips = ArrayTrait::new();
                let new_len = flips.len();
                // Copy all entries except the first (oldest)
                for i in 1..new_len {
                    new_flips.append(*flips.at(i));
                };
                flips = new_flips;
            }
            // Append the new flip
            flips.append((user, outcome, amount));

            let updated_len = flips.len();

            let mut k = 0;
            loop {
                if k == updated_len {
                    break;
                }

                // if recent flips vector is shorter then the updated length, then we need to
                // append, otherwise we overwrite
                if self.recent_flips.len() <= k.into() {
                    self.recent_flips.append().write(*flips.at(k));
                } else {
                    self.recent_flips.at(k.into()).write(*flips.at(k));
                }

                k += 1;
            };
        }

        fn _update_user_flips(
            ref self: ContractState, user: ContractAddress, outcome: bool, amount: u256,
        ) {
            // Copy the user's flips into a memory array using the getter.
            let mut flips = self.get_user_flips(user);
            let user_flips = self.get_user_flips(user);

            // Append the new flip record (a tuple of (bool, u256)).
            flips.append((outcome, amount));

            let updated_len = flips.len();

            let mut k = 0;
            loop {
                if k == updated_len {
                    break;
                }

                // if recent flips vector is shorter then the updated length, then we need to
                // append, otherwise we overwrite
                if user_flips.len() <= k.into() {
                    self.user_flips.entry(user).append().write(*flips.at(k));
                } else {
                    self.user_flips.entry(user).at(k.into()).write(*flips.at(k));
                }

                k += 1;
            };
        }

        fn _emit_config_update(ref self: ContractState) {
            self
                .emit(
                    ConfigUpdated {
                        min_bet: self.min_bet.read(),
                        max_bet: self.max_bet.read(),
                        house_edge: self.house_edge.read(),
                        timestamp: get_block_timestamp(),
                    },
                );
        }
    }
}
// Place a bet of 0.05 STRK on heads (true)
// await coinflipContract.play(true);

//  Or manually with custom amount:
// await coinflipContract.place_bet(true, "50000000000000000");
// await coinflipContract.flip_coin();

//  View functions
// const leaderboard = await coinflipContract.get_leaderboard();
// const balance = await coinflipContract.get_contract_balance();


