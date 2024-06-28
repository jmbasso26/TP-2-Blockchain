// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Member.sol";

contract DAO {

    Member public member;

    enum Category {General, Finanzas, Gubernamental, Desarrollo}
    // Struct para una Propuesta
    struct Proposal {
        string description;
        Category category;
        uint256 deadline;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        bool rejected;
        mapping(address => bool) voted;
    }

    // Variables de estado
    address public chairperson;
    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount;

    // Eventos
    event ProposalCreated(uint256 proposalId, string description, uint256 deadline);
    event VoteCast(address voter, uint256 proposalId, bool support);
    event ProposalExecuted(uint256 proposalId);
    event ProposalNotExecuted(uint256 proposalId, string reason);


    // Modificadores
    modifier onlyChairperson() {
        require(msg.sender == chairperson, "Solo el presidente puede realizar esta accion");
        _;
    }

    modifier onlyMember() {
        // Implementar lógica para verificar si el remitente es un miembro
        require(member.isMember(msg.sender), "Solo un miembro puede realizar esta accion");
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
    constructor(address _memberAddress) {
        chairperson = msg.sender;
        member = Member(_memberAddress);
    }

    // Función para crear una nueva propuesta (deben implementarla)
    function createProposal(string memory _description, Category _category ,uint256 _duration) external onlyMember{
        proposalCount++;
        Proposal storage newProposal = proposals[proposalCount];
        newProposal.description = _description;
        newProposal.category = _category;
        newProposal.deadline = block.timestamp + _duration*(60*60*24);
        newProposal.votesFor = 0;
        newProposal.votesAgainst = 0;
        newProposal.executed = false;
        newProposal.rejected = false;
        emit ProposalCreated(proposalCount, _description, newProposal.deadline);
    }

    // Función para votar en una propuesta (deben implementarla)
    function vote(uint256 _proposalId, bool _support) external onlyMember requireProposal(_proposalId){
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

    // Función para ejecutar una propuesta (deben implementarla)
    function executeProposal(uint256 _proposalId) external onlyChairperson requireProposal(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.deadline > block.timestamp, "La votacion no ha terminado aun");
        if((member.totalMembers() * 30 / 100) <= (proposal.votesFor + proposal.votesAgainst) && proposal.votesFor >= proposal.votesAgainst*2){
            proposal.executed = true;
            emit ProposalExecuted(_proposalId);
        }else{
            proposal.rejected = true;
            emit ProposalNotExecuted(_proposalId, "La propuesta no logro los votos necesarios para aprobarse");
        }
        
        
    }

    // Función para la administración de fondos (deben implementarla)
    function manageFunds() external onlyChairperson {

    }

    function quitPresidency() external onlyChairperson {

    }

    function electPresident() external onlyMember {

        
    }
}
