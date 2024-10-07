module my_addrx::Community {
    use aptos_framework::account;
    use std::signer;
    use aptos_framework::event;
    use std::string::String;
    use aptos_std::table::{Self, Table};
    use std::debug;
    use std::vector;

    // Errors
    const E_NOT_INITIALIZED: u64 = 1;
    const ECOMMUNITY_DOESNT_EXIST: u64 = 2;

    struct CommunitiesList has key {
        communities: Table<u64, Community>,
        community_counter: u64
    }

    struct ConfigProp has store, drop, copy {
        minimum_voice_power: u64,
        minimum_voice_age: u64
    }

    struct Config has store, drop, copy {
        post: ConfigProp,
        comment: ConfigProp,
        proposal: ConfigProp,
        poll: ConfigProp
    }

    #[event]
    struct Community has store, drop, copy {
        community_id: u64,
        address: address,
        config: Config
    }

    // Function to create a community list for an account
    public entry fun create_community_list(account: &signer) {
        let communities_list = CommunitiesList {
            communities: table::new(),
            community_counter: 0
        };
        move_to(account, communities_list);
    }

    // Function to create a new community
    public entry fun create_community(account: &signer, 
                                      min_voice_power_post: u64, 
                                      min_voice_age_post: u64, 
                                      min_voice_power_comment: u64, 
                                      min_voice_age_comment: u64, 
                                      min_voice_power_proposal: u64, 
                                      min_voice_age_proposal: u64, 
                                      min_voice_power_poll: u64, 
                                      min_voice_age_poll: u64) acquires CommunitiesList {
        let signer_address = signer::address_of(account);
        assert!(exists<CommunitiesList>(signer_address), E_NOT_INITIALIZED);

        let communities_list = borrow_global_mut<CommunitiesList>(signer_address);
        let counter = communities_list.community_counter + 1;

        let new_config = Config {
            post: ConfigProp { minimum_voice_power: min_voice_power_post, minimum_voice_age: min_voice_age_post },
            comment: ConfigProp { minimum_voice_power: min_voice_power_comment, minimum_voice_age: min_voice_age_comment },
            proposal: ConfigProp { minimum_voice_power: min_voice_power_proposal, minimum_voice_age: min_voice_age_proposal },
            poll: ConfigProp { minimum_voice_power: min_voice_power_poll, minimum_voice_age: min_voice_age_poll }
        };

        let new_community = Community {
            community_id: counter,
            address: signer_address,
            config: new_config
        };

        table::upsert(&mut communities_list.communities, counter, new_community);
        communities_list.community_counter = counter;

        event::emit(new_community);
    }

    // Function to get all communities for an account
    // public entry fun get_communities(account: address): vector<Community> acquires CommunitiesList {
    //     assert!(exists<CommunitiesList>(account), E_NOT_INITIALIZED);

    //     let communities_list = borrow_global<CommunitiesList>(account);
    //     let community_list = vector::empty<Community>();

    //     let keys = table::keys(&communities_list.communities);
    //     let n = vector::length(&keys);
    //     let i:u64 = 0;
    //     while (i < n) {
    //         let key = vector::borrow(&keys, i);
    //         let community = table::borrow(&communities_list.communities, &key);
    //         vector::push_back(&mut community_list, &community);
    //         i = i + 1;
    //     }

    //    community_list
    // debug::print(vector::borrow(&communities_list.communities, 0))
    // }

    // Test functions
    #[test(admin = @0x123)]
    public entry fun test_community_flow(admin: signer) acquires CommunitiesList {
        account::create_account_for_test(signer::address_of(&admin));
        create_community_list(&admin);

        create_community(
            &admin, 
            100, 30,     // Post config
            50, 15,      // Comment config
            200, 45,     // Proposal config
            75, 25       // Poll config
        );

        let communities_list = borrow_global<CommunitiesList>(signer::address_of(&admin));
        assert!(communities_list.community_counter == 1, 100);

        let created_community = table::borrow(&communities_list.communities, 1);
        assert!(created_community.community_id == 1, 101);
        assert!(created_community.config.post.minimum_voice_power == 100, 102);
        assert!(created_community.config.comment.minimum_voice_age == 15, 103);
    }

    #[test(admin = @0x123)]
    #[expected_failure(abort_code = E_NOT_INITIALIZED)]
    public entry fun test_community_list_not_initialized(admin: signer) acquires CommunitiesList {
        account::create_account_for_test(signer::address_of(&admin));
        create_community(
            &admin, 
            100, 30,     // Post config
            50, 15,      // Comment config
            200, 45,     // Proposal config
            75, 25       // Poll config
        );
    }
}
