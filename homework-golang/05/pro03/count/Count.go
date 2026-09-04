// Code generated - DO NOT EDIT.
// This file is a generated binding and any manual changes will be lost.

package count

import (
	"context"
	"errors"
	"math/big"
	"strings"
	"time"

	ethereum "github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/event"
)

// Reference imports to suppress errors if they are not otherwise used.
var (
	_ = errors.New
	_ = big.NewInt
	_ = strings.NewReader
	_ = ethereum.NotFound
	_ = bind.Bind
	_ = common.Big1
	_ = types.BloomLookup
	_ = event.NewSubscription
	_ = abi.ConvertType
	_ = time.Tick
	_ = context.Background
)

// CountMetaData contains all meta data concerning the Count contract.
var CountMetaData = &bind.MetaData{
	ABI: "[{\"inputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"constructor\"},{\"anonymous\":false,\"inputs\":[{\"indexed\":false,\"internalType\":\"uint256\",\"name\":\"newCount\",\"type\":\"uint256\"}],\"name\":\"CountUpdated\",\"type\":\"event\"},{\"inputs\":[],\"name\":\"getCount\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"increment\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"}]",
	Bin: "0x608060405234801561000f575f80fd5b505f805560f58061001f5f395ff3fe6080604052348015600e575f80fd5b50600436106030575f3560e01c8063a87d942c146034578063d09de08a146048575b5f80fd5b5f5460405190815260200160405180910390f35b604e6050565b005b60015f80828254605f9190609b565b90915550505f546040519081527f06bef5f47a1a400f9ceb1f3700a329a4ced09a400f88dd3230d93e4c104c907f9060200160405180910390a1565b8082018082111560b957634e487b7160e01b5f52601160045260245ffd5b9291505056fea2646970667358221220e52499b279be872d74f0fb96ada5fc5fdf6683d2b814d6c4fc40468ec319b95e64736f6c63430008180033",
}

// CountABI is the input ABI used to generate the binding from.
// Deprecated: Use CountMetaData.ABI instead.
var CountABI = CountMetaData.ABI

// CountBin is the compiled bytecode used for deploying new contracts.
// Deprecated: Use CountMetaData.Bin instead.
var CountBin = CountMetaData.Bin

// DeployCount deploys a new Ethereum contract, binding an instance of Count to it.
func DeployCount(auth *bind.TransactOpts, backend bind.ContractBackend) (common.Address, *types.Transaction, *Count, error) {
	parsed, err := CountMetaData.GetAbi()
	if err != nil {
		return common.Address{}, nil, nil, err
	}
	if parsed == nil {
		return common.Address{}, nil, nil, errors.New("GetABI returned nil")
	}

	address, tx, contract, err := bind.DeployContract(auth, *parsed, common.FromHex(CountBin), backend)
	if err != nil {
		return common.Address{}, nil, nil, err
	}
	return address, tx, &Count{CountCaller: CountCaller{contract: contract}, CountTransactor: CountTransactor{contract: contract}, CountFilterer: CountFilterer{contract: contract}}, nil
}

// Count is an auto generated Go binding around an Ethereum contract.
type Count struct {
	CountCaller     // Read-only binding to the contract
	CountTransactor // Write-only binding to the contract
	CountFilterer   // Log filterer for contract events
}

// CountCaller is an auto generated read-only Go binding around an Ethereum contract.
type CountCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// CountTransactor is an auto generated write-only Go binding around an Ethereum contract.
type CountTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// CountFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type CountFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// CountSession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type CountSession struct {
	Contract     *Count            // Generic contract binding to set the session for
	CallOpts     bind.CallOpts     // Call options to use throughout this session
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// CountCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type CountCallerSession struct {
	Contract *CountCaller  // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts // Call options to use throughout this session
}

// CountTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type CountTransactorSession struct {
	Contract     *CountTransactor  // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// CountRaw is an auto generated low-level Go binding around an Ethereum contract.
type CountRaw struct {
	Contract *Count // Generic contract binding to access the raw methods on
}

// CountCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type CountCallerRaw struct {
	Contract *CountCaller // Generic read-only contract binding to access the raw methods on
}

// CountTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type CountTransactorRaw struct {
	Contract *CountTransactor // Generic write-only contract binding to access the raw methods on
}

// NewCount creates a new instance of Count, bound to a specific deployed contract.
func NewCount(address common.Address, backend bind.ContractBackend) (*Count, error) {
	contract, err := bindCount(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &Count{CountCaller: CountCaller{contract: contract}, CountTransactor: CountTransactor{contract: contract}, CountFilterer: CountFilterer{contract: contract}}, nil
}

// NewCountCaller creates a new read-only instance of Count, bound to a specific deployed contract.
func NewCountCaller(address common.Address, caller bind.ContractCaller) (*CountCaller, error) {
	contract, err := bindCount(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &CountCaller{contract: contract}, nil
}

// NewCountTransactor creates a new write-only instance of Count, bound to a specific deployed contract.
func NewCountTransactor(address common.Address, transactor bind.ContractTransactor) (*CountTransactor, error) {
	contract, err := bindCount(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &CountTransactor{contract: contract}, nil
}

// NewCountFilterer creates a new log filterer instance of Count, bound to a specific deployed contract.
func NewCountFilterer(address common.Address, filterer bind.ContractFilterer) (*CountFilterer, error) {
	contract, err := bindCount(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &CountFilterer{contract: contract}, nil
}

// bindCount binds a generic wrapper to an already deployed contract.
func bindCount(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := CountMetaData.GetAbi()
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, *parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_Count *CountRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _Count.Contract.CountCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_Count *CountRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _Count.Contract.CountTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_Count *CountRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _Count.Contract.CountTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_Count *CountCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _Count.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_Count *CountTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _Count.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_Count *CountTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _Count.Contract.contract.Transact(opts, method, params...)
}

// GetCount is a free data retrieval call binding the contract method 0xa87d942c.
//
// Solidity: function getCount() view returns(uint256)
func (_Count *CountCaller) GetCount(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _Count.contract.Call(opts, &out, "getCount")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetCount is a free data retrieval call binding the contract method 0xa87d942c.
//
// Solidity: function getCount() view returns(uint256)
func (_Count *CountSession) GetCount() (*big.Int, error) {
	return _Count.Contract.GetCount(&_Count.CallOpts)
}

// GetCount is a free data retrieval call binding the contract method 0xa87d942c.
//
// Solidity: function getCount() view returns(uint256)
func (_Count *CountCallerSession) GetCount() (*big.Int, error) {
	return _Count.Contract.GetCount(&_Count.CallOpts)
}

// Increment is a paid mutator transaction binding the contract method 0xd09de08a.
//
// Solidity: function increment() returns()
func (_Count *CountTransactor) Increment(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _Count.contract.Transact(opts, "increment")
}

// Increment is a paid mutator transaction binding the contract method 0xd09de08a.
//
// Solidity: function increment() returns()
func (_Count *CountSession) Increment() (*types.Transaction, error) {
	return _Count.Contract.Increment(&_Count.TransactOpts)
}

// Increment is a paid mutator transaction binding the contract method 0xd09de08a.
//
// Solidity: function increment() returns()
func (_Count *CountTransactorSession) Increment() (*types.Transaction, error) {
	return _Count.Contract.Increment(&_Count.TransactOpts)
}

// CountCountUpdatedIterator is returned from FilterCountUpdated and is used to iterate over the raw logs and unpacked data for CountUpdated events raised by the Count contract.
type CountCountUpdatedIterator struct {
	Event *CountCountUpdated // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *CountCountUpdatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(CountCountUpdated)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(CountCountUpdated)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *CountCountUpdatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *CountCountUpdatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// CountCountUpdated represents a CountUpdated event raised by the Count contract.
type CountCountUpdated struct {
	NewCount *big.Int
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterCountUpdated is a free log retrieval operation binding the contract event 0x06bef5f47a1a400f9ceb1f3700a329a4ced09a400f88dd3230d93e4c104c907f.
//
// Solidity: event CountUpdated(uint256 newCount)
func (_Count *CountFilterer) FilterCountUpdated(opts *bind.FilterOpts) (*CountCountUpdatedIterator, error) {

	logs, sub, err := _Count.contract.FilterLogs(opts, "CountUpdated")
	if err != nil {
		return nil, err
	}
	return &CountCountUpdatedIterator{contract: _Count.contract, event: "CountUpdated", logs: logs, sub: sub}, nil
}

// WatchCountUpdated is a free log subscription operation binding the contract event 0x06bef5f47a1a400f9ceb1f3700a329a4ced09a400f88dd3230d93e4c104c907f.
//
// Solidity: event CountUpdated(uint256 newCount)
func (_Count *CountFilterer) WatchCountUpdated(opts *bind.WatchOpts, sink chan<- *CountCountUpdated) (event.Subscription, error) {

	logs, sub, err := _Count.contract.WatchLogs(opts, "CountUpdated")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(CountCountUpdated)
				if err := _Count.contract.UnpackLog(event, "CountUpdated", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseCountUpdated is a log parse operation binding the contract event 0x06bef5f47a1a400f9ceb1f3700a329a4ced09a400f88dd3230d93e4c104c907f.
//
// Solidity: event CountUpdated(uint256 newCount)
func (_Count *CountFilterer) ParseCountUpdated(log types.Log) (*CountCountUpdated, error) {
	event := new(CountCountUpdated)
	if err := _Count.contract.UnpackLog(event, "CountUpdated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
