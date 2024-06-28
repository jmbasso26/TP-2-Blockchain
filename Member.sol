// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Member {

    enum Role {Miembro, Directivo, Presidente}

    struct Members{
        address id;
        Role role;
        bool isActive;
    }

    struct PromotionRequest{
        address id;
        Role newrole;
        uint256 approvals;
        mapping(address => bool) approvers;
    }

    // Variables de estado
    mapping(address => Members) public members;
    mapping(address => PromotionRequest) public promotionRequests;
    uint256 private activeMember;

    // Eventos
    event President(address member);
    event MemberAdded(address member);
    event MemberPromoted(address member, Role newRole);
    event MemberRemoved(address member);
    event PromotionInitiated(address member, Role newRole);
    event PromotionApproved(address member);

    // Modificadores 
    modifier OnlyPresident(){
        require(members[msg.sender].role == Role.Directivo, "Solo el presidente puede llamar a esta funcion");
        _;
    }

    modifier OnlyExecutive(){
        require(members[msg.sender].role == Member.Role.Directivo, "Solo un directivo puede llamar a esta funcion");
        _;
    }

    modifier OnlyMember(){
        require(members[msg.sender].role == Role.Miembro, "Solo un miembro puede llamar a esta funcion");
        _;
    }

    modifier OnlyPresident_Executive(){
        require(members[msg.sender].role == Role.Presidente || members[msg.sender].role == Role.Directivo, "Solo un directivo o el presidente pueden llamar esta funcion");
        _;
    }

    modifier AllMembers(){
        require(members[msg.sender].isActive, "Solo los miembros del partido pueden llamar a esta funcion");
        _;
    }

    // Constructor
    constructor(){
        members[msg.sender] = Members({
            id: msg.sender,
            role: Role.Presidente,
            isActive: true
        });
        activeMember+=1000;
        emit President(msg.sender);
    }

    // Función para añadir un nuevo miembro
    function addMember(address _member) external AllMembers {
        // Implementar
        require(!members[_member].isActive, "La direccion ya ha sido utilizada anteriormente");
        members[_member] = Members({
            id : _member,
            role: Role.Miembro,
            isActive : true});
        activeMember+=1000;
        emit MemberAdded(_member);
    }

    function getMemberDetails(address _member) external view returns (address, Role, bool) {
        Members storage member = members[_member];
        return (member.id, member.role, member.isActive);
    }

    function initiatePromotion() external OnlyMember{
        PromotionRequest storage request = promotionRequests[msg.sender];
        request.id = msg.sender;
        request.newrole = Role.Directivo;
        request.approvals = 0;
        emit PromotionInitiated(msg.sender, request.newrole);
    }

    function approvePromotion(address _candidate) external OnlyMember{
        PromotionRequest storage request = promotionRequests[_candidate];
        require(request.id != address(0), "Este miembro no ha solicitado una promocion");
        require(!request.approvers[msg.sender], "Ya has aprobado esta solicitud");
        request.approvers[msg.sender] = true;
        request.approvals+=1000;
        if(request.approvals > activeMember*5/100){
            //Members storage member = members[_candidate];
            members[_candidate].role = Role.Directivo;
            delete promotionRequests[_candidate];
            emit PromotionApproved(_candidate);
        }
    }

    function getPromotionRequest(address _member) external view returns (address, Role, uint256) {
        PromotionRequest storage request = promotionRequests[_member];
        return (request.id, request.newrole, request.approvals);
    }

    // Función para eliminar un miembro
    function removeMember(address _member) external OnlyExecutive {
        // Implementar 
        require(members[_member].isActive, "La direccion no pertenece a ningun miembro");
        members[_member].isActive = false;
        activeMember-=1000;
        emit MemberRemoved(_member);
    }

    // Función para verificar si una dirección es miembro
    function isMember(address _address) external view returns (bool) {
        // Implementar 
        return members[_address].isActive;
    }

    function totalMembers() external view returns (uint256) {
        if (activeMember == 0) {
            return activeMember;
        } else {
            return activeMember / 1000;
    }

    }

}

