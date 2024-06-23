// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Member.sol";

contract DAO {

    Member public member;
    // Struct para una Propuesta
    struct Proposal {
        string description;
        uint256 deadline;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
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

    // Modificadores
    modifier onlyChairperson() {
        require(msg.sender == chairperson, "Solo el presidente puede realizar esta accion");
        _;
    }

    modifier onlyMember() {
        // Implementar lógica para verificar si el remitente es un miembro
        require(member.isMember(msg.sender) == true, "Solo un miembro puede realizar esta accion");
        _;
    }

    // Constructor
    constructor(address _memberAddress) {
        chairperson = msg.sender;
        member = Member(_memberAddress);
    }

    // Función para crear una nueva propuesta (deben implementarla)
    function createProposal(string memory _description, uint256 _duration) external onlyMember {
        proposalCount++;
        Proposal storage newProposal = proposals[proposalCount];
        newProposal.description = _description;
        newProposal.deadline = block.timestamp + _duration;
        newProposal.votesFor = 0;
        newProposal.votesAgainst = 0;
        newProposal.executed = false;
        emit ProposalCreated(proposalCount, _description, newProposal.deadline);
    }

    // Función para votar en una propuesta (deben implementarla)
    function vote(uint256 _proposalId, bool _support) external onlyMember {
        require(_proposalId > 0 && _proposalId <= proposalCount++, "La propuesta no existe");
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.deadline < block.timestamp, "La propuesta ya no es valida");
        require(proposal.executed, "La propuesta ya ha sido ejecutada");
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
    function executeProposal(uint256 _proposalId) external onlyChairperson {
        return;
    }

    // Función para la administración de fondos (deben implementarla)
    function manageFunds() external onlyChairperson {

    }
}
