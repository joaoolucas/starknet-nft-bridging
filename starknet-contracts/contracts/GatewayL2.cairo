%lang starknet
%builtins pedersen range_check ecdsa

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.math import assert_not_equal, assert_not_zero

@storage_var
func owners(token_id : felt) -> (res : felt){
}

@storage_var
func balances(owner : felt) -> (res : felt){
}

@storage_var
func token_approvals(token_id : felt) -> (res : felt){
}

@storage_var
func operator_approvals(owner : felt, operator : felt) -> (res : felt){
}

@storage_var
func initialized() -> (res : felt){
}

@storage_var
func name_() -> (res : felt){
}

@storage_var
func symbol_() -> (res : felt){
}

struct BlockchainNamespace{
    member_a : felt,
}

struct BlockchainReference{
    member_a : felt,
}

struct AssetNamespace{
    member_a : felt,
}

struct AssetReference{
    member_a : felt,
}

struct TokenId{
    member_a : felt,
    member_b : felt,
    member_c : felt,
}

struct TokenUri{
    member_blockchain_namespace : BlockchainNamespace,
    member_blockchain_reference : BlockchainReference,
    member_asset_namespace : AssetNamespace,
    member_asset_reference : AssetReference,
    member_token_id : TokenId,
}

@storage_var
func token_uri_() -> (res : TokenUri){
}

@external
func initialize{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
        name : felt, symbol : felt, tokenURI : TokenUri){
    let (_initialized) = initialized.read();
    assert _initialized = 0;

    name_.write(name);
    symbol_.write(name);
    token_uri_.write(tokenURI);

    initialized.write(1);

    return ();
}

@view
func balance_of{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        owner : felt) -> (res : felt){
    assert_not_zero(owner);

    let (res) = balances.read(owner=owner);
    return (res = res);
}

@view
func owner_of{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : felt) -> (res : felt){
    let (res) = owners.read(token_id=token_id);
    assert_not_zero(res);

    return (res = res);
}

@view
func name{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (res : felt){
    let (res) = name_.read();
    return (res = res);
}

@view
func symbol{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (res : felt){
    let (res) = symbol_.read();

    return (res = res);
}

@view
func token_uri{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : felt) -> (res : TokenUri){
    let (res) = token_uri_.read();

    return (res = res);
}

func _approve{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        to : felt, token_id : felt){
    token_approvals.write(token_id=token_id, value=to);
    return ();
}

@external
func approve{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
        to : felt, token_id : felt){
    let (owner) = owners.read(token_id);

    assert_not_equal(owner, to);

    let (is_operator_or_owner) = _is_operator_or_owner(owner);
    assert_not_zero(is_operator_or_owner);

    _approve(to, token_id);
    return ();
}

func _is_operator_or_owner{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
        address : felt) -> (res : felt){
    let (caller) = get_caller_address();


    if (caller == address){
        return (res = 1);
    }

    let (is_approved_for_all) = operator_approvals.read(owner=caller, operator=address);
    return (res = is_approved_for_all);
}

func _is_approved_or_owner{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
        sper : felt, token_id : felt) -> (res : felt){
    alloc_locals;

    let (exists) = _exists(token_id);
    assert exists = 1;

    let (owner) = owner_of(token_id);
    if (owner == sper){
        return (res = 1);
    }

    let (approved_addr) = get_approved(token_id);
    if (approved_addr == sper){
        return (res = 1);
    }

    let (is_operator) = is_approved_for_all(owner, sper);
    if (is_operator == 1){
        return (res = 1);
    }

    return (res = 0);
}

func _exists{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : felt) -> (res : felt){
    let (res) = owners.read(token_id);

    if (res == 0){
        return (res = 0);
    }else{
        return (res = 1);
    }
}

@view
func get_approved{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : felt) -> (res : felt){
    let (exists) = _exists(token_id);
    assert exists = 1;

    let (res) = token_approvals.read(token_id=token_id);
    return (res = res);
}

@view
func is_approved_for_all{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        owner : felt, operator : felt) -> (res : felt){
    let (res) = operator_approvals.read(owner=owner, operator=operator);
    return (res = res);
}

func _mint{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
        to : felt, token_id : felt){
    assert_not_zero(to);

    let (exists) = _exists(token_id);
    assert exists = 0;

    let (balance) = balances.read(to);
    balances.write(to, balance + 1);

    owners.write(token_id, to);

    return ();
}

func _burn{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(token_id : felt){
    alloc_locals;

    let (local owner) = owner_of(token_id);

    _approve(0, token_id);

    let (balance) = balances.read(owner);
    balances.write(owner, balance - 1);

    owners.write(token_id, 0);

    return ();
}

func _transfer{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _from : felt, to : felt, token_id : felt){
    let (_owner_of) = owner_of(token_id);
    assert _owner_of = _from;

    assert_not_zero(to);

    _approve(0, token_id);

    let (owner_bal) = balances.read(_from);
    balances.write(owner=_from, value=(owner_bal - 1));

    let (receiver_bal) = balances.read(to);
    balances.write(owner=to, value=(receiver_bal + 1));

    owners.write(token_id=token_id, value=to);

    return ();
}

func _set_approval_for_all{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        owner : felt, operator : felt, approved : felt){
    assert_not_equal(owner, operator);

    assert approved * (1 - approved) = 0;

    operator_approvals.write(owner=owner, operator=operator, value=approved);
    return ();
}

@external
func set_approval_for_all{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        operator : felt, approved : felt){
    let (caller) = get_caller_address();

    _set_approval_for_all(caller, operator, approved);
    return ();
}

@external
func transfer_from{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
        _from : felt, to : felt, token_id : felt){
    let (caller) = get_caller_address();
    _is_approved_or_owner(caller, token_id=token_id);

    _transfer(_from, to, token_id);
    return ();
}
