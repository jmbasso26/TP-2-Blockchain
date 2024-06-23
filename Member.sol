// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Member {
    struct Members{
        address _address;
        bool _isMember;
    }
    // Variables de estado
    mapping(address => Members) public members;
    address public owner;

    // Eventos
    event MemberAdded(address member);
    event MemberRemoved(address member);

    // Modificadores 
    modifier OnlyOwner(){
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    // Constructor
    constructor(){
        owner = msg.sender;
    }

    // Función para añadir un nuevo miembro
    function addMember(address _member) external OnlyOwner {
        // Implementar
        require(!members[_member]._isMember, "Address is already a member");
        members[_member] = Members(_member, true);
        emit MemberAdded(_member);
    }

    // Función para eliminar un miembro
    function removeMember(address _member) external OnlyOwner {
        // Implementar 
        require(members[_member]._isMember, "Address is not a member");
        members[_member]._isMember = false;
        emit MemberRemoved(_member);
    }

    // Función para verificar si una dirección es miembro
    function isMember(address _address) external view returns (bool) {
        // Implementar 
        return members[_address]._isMember;
    }
}
