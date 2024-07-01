// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Member.sol";

contract DAO is Member {

    enum Category {General, Finanzas, Gubernamental, Desarrollo}

    // Struct para propuestas
    struct Proposal {
        address owner;
        string description;
        Category category;
        //uint requiredMembers;
        uint256 deadline;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        bool rejected;
        mapping(address => bool) voted;

    }
    // Struct para candidatos
    struct Candidate {
        address candidateAddress;
        uint256 voteCount;
    }
    // Struct para elecciones a presidente
    struct Election {
        bool isActive;
        uint256 startTime;
        uint256 endTime;
        Candidate[] candidates;
        mapping(address => bool) hasVoted;
    }


    // Variables de estado
    mapping(uint256 => Proposal) public proposals;
    //mapping(uint256 => Task[]) public proposalTasks;
    uint256 public proposalCount;
    Election public currentElection;
    address public president;

    // Eventos

    //Elecciones
    event ElectionStarted(uint256 endTime);
    event CandidateNominated(address candidate);
    event CandidateVoted(uint candidate);
    event ElectionEnded(address winner);
    //Propuestas
    event ProposalCreated(uint256 proposalId, string description, uint256 deadline);
    event ProposalExecuted(uint256 proposalId);
    event ProposalNotExecuted(uint256 proposalId, string reason);
    //Participantes
    event VoteCast(address voter, uint256 proposalId, bool support);
    event ProposalNewRequestToParticipate(uint256 proposalId, address member);
    event ProposalNewParticipant(uint256 proposalId, address member);
    event TaskCompleted(uint256 proposalId, uint256 _id, address member);

    // Modificadores
    modifier onlyPresident(){
        require(members[msg.sender].role == Role.Presidente, "Solo el presidente puede realizar esta accion");
        _;
    }

    modifier onlyPresidentOrExecutive(){
        require(members[msg.sender].role == Role.Presidente || members[msg.sender].role == Role.Directivo, "Solo el presidente puede realizar esta accion");
        _;
    }

    modifier onlyMember() {
        // Implementar lógica para verificar si el remitente es un miembro
        require(this.isMember(msg.sender), "Debe ser un miembro");
        _;
    }

    modifier onlyExecutive() {
        // Implementar lógica para verificar si el remitente es un miembro
        require(members[msg.sender].role == Role.Directivo, "Solo un directivo puede llamar a esta funcion");
        _;
    }

    modifier onlyOwnerAndExecutive(uint256 _proposalId){
        require(proposals[_proposalId].owner == msg.sender || members[msg.sender].role == Role.Directivo, "Solo el duenio de la propuesta o un directivo pueden llamar a esta funcion");
        _;
    }

    modifier requireProposal(uint256 _proposalId){
        require(_proposalId > 0 && _proposalId <= proposalCount, "La propuesta no existe");
        require(!proposals[_proposalId].executed, "La propuesta ya ha sido ejecutada");
        require(!proposals[_proposalId].rejected, "La propuesta ya ha sido rechazada");
        _;
    }

    modifier proposalExists(uint256 _proposalId){
        require(_proposalId > 0 && _proposalId <= proposalCount, "La propuesta no existe");
        _;
    }

    modifier notExecuted(uint256 _proposalId){
        require(!proposals[_proposalId].executed, "La propuesta ya ha sido ejecutada");
        _;
    }

    // Constructor
    constructor() {
        president = msg.sender;
        members[president] = Members({
            id: msg.sender,
            role: Role.Presidente,
            isActive: true
        });
        activeMember += 1000;
    }

    //Funciones

    //Eleccion presidente

    function startElection(uint256 _duration) external onlyPresident {
        require(!currentElection.isActive, "There is already an active election.");
        currentElection.isActive = true;
        currentElection.startTime = block.timestamp;
        currentElection.endTime = block.timestamp + (_duration*1 days);
        delete currentElection.candidates; // Resetear la lista de candidatos
        emit ElectionStarted(_duration);
    }

    function isActive() external view returns (bool){
        return currentElection.isActive;
    }

    //Permite a un ejecutivo presentarse a la eleccion
    function nominateCandidate() external onlyExecutive {
        require(currentElection.isActive, "La eleccion debe estar activa");
        require(block.timestamp < currentElection.endTime, "La eleccion ya ha terminado");
        currentElection.candidates.push(Candidate({
        candidateAddress: msg.sender,
        voteCount: 0
        }));
        emit CandidateNominated(msg.sender);
    }

    function voteElection(uint256 candidateIndex) external onlyMember{
        require(currentElection.isActive, "No active election.");
        require(!currentElection.hasVoted[msg.sender], "You have already voted.");
        require(block.timestamp < currentElection.endTime, "Voting period has ended.");
        require(candidateIndex < currentElection.candidates.length, "Invalid candidate index.");

        currentElection.candidates[candidateIndex].voteCount++;
        currentElection.hasVoted[msg.sender] = true;
        emit CandidateVoted(candidateIndex);

    }
    //Devuelve las direcciones de los candidatsos
    function getCandidateAddresses() public view returns (address[] memory) {
        address[] memory addresses = new address[](currentElection.candidates.length);
        for (uint i = 0; i < currentElection.candidates.length; i++) {
            addresses[i] = currentElection.candidates[i].candidateAddress;
        }
        return addresses;
    }
    //Da por finalizada la eleccion
    function endElection() external onlyPresidentOrExecutive{
        require(currentElection.isActive, "No active election to end.");
        require(block.timestamp >= currentElection.endTime, "Election period has not ended yet.");
    
        uint256 winningVoteCount = 0;
        address winningCandidate;
        bool tie;

        for (uint i = 0; i < currentElection.candidates.length; i++) {
            if (currentElection.candidates[i].voteCount > winningVoteCount) {
                winningVoteCount = currentElection.candidates[i].voteCount;
                winningCandidate = currentElection.candidates[i].candidateAddress;
                tie = false;
            }else if(currentElection.candidates[i].voteCount == winningVoteCount){
                tie = true;
            }
        }
        currentElection.isActive = false;
        if(tie){
            this.startElection(1);
        }else{
            members[winningCandidate].role = Role.Presidente;
            members[president].role = Role.Directivo;
            emit ElectionEnded(winningCandidate);
        }

    }



    //Propuestas
    
    function createProposal(string memory _description, Category _category, uint256 _duration) external onlyMember{
        proposalCount++;
        Proposal storage newProposal = proposals[proposalCount];
        newProposal.owner = msg.sender;
        newProposal.description = _description;
        newProposal.category = _category;
        newProposal.deadline = block.timestamp + (_duration*1 days);
        newProposal.votesFor = 0;
        newProposal.votesAgainst = 0;
        newProposal.executed = false;
        newProposal.rejected = false;
        //newProposal.participants.push(msg.sender);
        emit ProposalCreated(proposalCount, _description, newProposal.deadline);
    }
    /*

    function requestToParticipate(uint256 _proposalId) external onlyMember requireProposal(_proposalId){
        require(proposals[_proposalId].requiredMembers > 0, "La propuesta ya tiene los miembros necesarios para llevarse a cabo");
        require(!isParticipant(_proposalId, msg.sender), "El miembro solicitante ya forma parte de la propuesta");
        require(!isRequestedParticipant(_proposalId, msg.sender), "El miembro ya ha solicitado participar");
        proposals[_proposalId].posible_participants.push(msg.sender);
        emit ProposalNewRequestToParticipate(_proposalId, msg.sender);
    }
    */

    function voteProposal(uint256 _proposalId, bool _support) external onlyMember requireProposal(_proposalId){
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.deadline > block.timestamp, "La propuesta ya no es valida");
        require(!proposal.voted[msg.sender], "Ya has votado");
        proposal.voted[msg.sender] = true;
        if (_support){
            proposal.votesFor++;
        }else{
            proposal.votesAgainst++;
        }
        emit VoteCast(msg.sender, _proposalId, _support);
    }

    /*

    function addTaskToProposal(uint256 _proposalId, string memory _taskDescription, Member.Role _role) external onlyOwnerAndExecutive(_proposalId) {
        Task memory newTask = Task({
            id: proposalTasks[_proposalId].length,
            description: _taskDescription,
            isCompleted: false,
            assignee: address(0) ,  // Asume que inicialmente no hay asignados
            roleRequired: _role// Asume que hay un valor por defecto
        });
        proposalTasks[_proposalId].push(newTask);
    }


    function addMemberToTask(uint256 _proposalId, uint256 _id, address _member) external onlyOwnerAndExecutive(_proposalId) {
        require(isParticipant(_proposalId, _member), "El miembro no pertenece a la propuesta");
        require(members[msg.sender].role == proposalTasks[_proposalId][_id].roleRequired, "El miembro no tiene el rol requerido para realizar esta funcion");
        proposalTasks[_proposalId][_id].assignee = _member;

    }
    

    function executeTask(uint256 _proposalId, uint256 _id) external onlyMember{
        require(proposalTasks[_proposalId][_id].assignee == msg.sender, "El miembro no tiene asignada esta tarea");
        proposalTasks[_proposalId][_id].isCompleted = true;
        emit TaskCompleted(_proposalId, _id, msg.sender);
    }

    function approveParticipant(uint256 _proposalId, address _member) external onlyOwnerAndExecutive(_proposalId) requireProposal(_proposalId){
        require(isRequestedParticipant(_proposalId, _member), "El miembro nunca solicito participar");
        require(!isParticipant(_proposalId, _member), "El miembro ya participa");
        proposals[_proposalId].participants.push(_member);
        removeRequestedParticipant(_proposalId, _member);
        emit ProposalNewParticipant(_proposalId, _member);
    }
    */

    function executeProposal(uint256 _proposalId) external onlyPresident requireProposal(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.deadline > block.timestamp, "La votacion no ha terminado aun");
        //require(allTaskCompleted(_proposalId), "Aun quedan tareas por completar");
        if((this.totalMembers() * 30 / 100) <= (proposal.votesFor*1000 + proposal.votesAgainst*1000) && proposal.votesFor >= proposal.votesAgainst*2){
            proposal.executed = true;
            emit ProposalExecuted(_proposalId);
        }else{
            proposal.rejected = true;
            emit ProposalNotExecuted(_proposalId, "La propuesta no logro los votos necesarios para aprobarse");
        }    
    }
/*
    function getPotentialParticipants(uint256 _proposalId) external view onlyOwnerAndExecutive(_proposalId) requireProposal(_proposalId) returns (address[] memory){
        return proposals[_proposalId].posible_participants;

    
    }

*/


/*

    //Privadas

    
    function isParticipant(uint256 _proposalId, address _member) private view returns (bool){
        address[] memory participants = proposals[_proposalId].participants;
        for (uint i = 0; i< participants.length; i++){
            if (participants[i] == _member){
                return true;
            }
        }
        return false;
    }

    function isRequestedParticipant(uint256 _proposalId, address _member) private view returns (bool){
        address[] memory requestedParticipants = proposals[_proposalId].posible_participants;
        for (uint i = 0; i< requestedParticipants.length; i++){
            if (requestedParticipants[i] == _member){
                return true;
            }
        }
        return false;
    }

    function removeRequestedParticipant(uint256 _proposalId, address _member) private {
        address[] storage possibleParticipants = proposals[_proposalId].posible_participants;
        uint256 length = possibleParticipants.length;
        for (uint i = 0; i < length; i++) {
            if (possibleParticipants[i] == _member) {
                if (i != length - 1) {
                    possibleParticipants[i] = possibleParticipants[length - 1];
                }
                possibleParticipants.pop();
                break;
            }
        }
    }

    function allTaskCompleted(uint256 _proposalId) private view returns (bool) {
        for(uint i = 0; i<proposalTasks[_proposalId].length; i++){
            if (proposalTasks[_proposalId][i].isCompleted == false){
                return false;
            }
        }
        return true;
    }
*/

}
