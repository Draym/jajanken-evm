pragma solidity ^0.7.4;

// SPDX-License-Identifier: GLWTPL
contract SignerGuardian {

    address public signer;

    constructor(address _signer) {
        signer = _signer;
    }

    function _verifyMessage(bytes32 _messageHash, bytes memory _signature) internal view returns (bool){
        return _recover(_messageHash, _signature) == signer;
    }

    function _recover(bytes32 _messageHash, bytes memory _signature) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = _split(_signature);
        return ecrecover(_messageHash, v, r, s);
    }

    function _split(bytes memory _signature) internal pure returns (bytes32 r, bytes32 s, uint8 v){
        require(_signature.length == 65, "invalid signature length");
        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }
    }
}