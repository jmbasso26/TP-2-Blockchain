const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("DAO Contract", function () {
    let DAO;
    let dao;
    let owner;
    let executive1;
    let executive2;
    let member1;
    let member2;
    let member3;
    let addr1;
    let addr2;
    let addr3
    let addrs;

    beforeEach(async function () {
        [owner, executive1,executive2, member1, member2, member3,addr1, addr2, addr3, ...addrs] = await ethers.getSigners();
         
        DAO = await ethers.getContractFactory("DAO");
        dao = await DAO.deploy();
        
        await dao.addMember(addr1.address);
        await dao.addMember(addr2.address);
        await dao.addMember(addr3.address);
        await dao.addMember(member1.address);
        await dao.addMember(member2.address);
        await dao.addMember(executive1.address);
        await dao.addMember(executive2.address);
        await dao.connect(executive1).initiatePromotion();
        await dao.connect(executive2).initiatePromotion();
        await dao.connect(addr1).approvePromotion(executive1.address);
        await dao.connect(addr1).approvePromotion(executive2.address);

    });

    describe("Roles Miembro", function(){
        it("should allow adding a new dao", async function () {
        await expect(dao.addMember(member3.address))
            .to.emit(dao, 'MemberAdded')
            .withArgs(member3.address);
        });
        
        it("Debe permitir a los miembros candidatearse como directivos", async function () {
            await expect(dao.connect(member1).initiatePromotion())
            .to.emit(dao, 'PromotionInitiated')
            .withArgs(member1.address, 1);  // Suponiendo que 1 es el Role.Directivo
        });
        
        it("Debe aprobar la solicitud y cambiar el rol", async function () {
            // Asegurar que la promoción se haya iniciado correctamente para addr1
            await dao.connect(member1).initiatePromotion();
            await expect(dao.connect(member2).approvePromotion(member1.address))
              .to.emit(dao, 'PromotionApproved')
              .withArgs(member1.address);
        
            const memberDetails = await dao.getMemberDetails(member1.address);
            expect(memberDetails[1]).to.equal(1);  // Verifica que el rol se ha actualizado a Directivo
        });
        
        it("Debe devolver los datos de solicitud", async function () {
            await dao.connect(member2).initiatePromotion();  // Asegura que la promoción se inicia
            const promotionDetails = await dao.getPromotionRequest(member2.address);
            expect(promotionDetails[0]).to.equal(member2.address);
            expect(promotionDetails[1]).to.equal(1);  // Role esperado
            expect(promotionDetails[2]).to.equal(0);  // Aprobaciones, deben ser 0 inicialmente
        });
        
        it("Debe permitir a un ejecutivo remover a un miembro", async function () {
        
            // addr1, siendo Directivo, intenta eliminar a addr2
            await expect(dao.connect(executive1).removeMember(member2.address))
              .to.emit(dao, 'MemberRemoved')
              .withArgs(member2.address);
        
            // Verificar que addr2 ya no es un miembro activo
            expect(await dao.isMember(member2.address)).to.be.false;
        });
          
        it("Owner debe ser el presidente", async function(){
            const memberDetails = await dao.getMemberDetails(owner.address);
            expect(memberDetails[1]).to.equal(2); //Role presidente esperado
        });

    });
    
    describe("Propuestas", function(){
        it("Crear Propuesta", async function(){
            
            await expect(dao.connect(addr1).createProposal("DAO", 1, 1))
                .to.emit(dao, "ProposalCreated")
        });
        it("Votar propuesta", async function(){
            await dao.connect(addr1).createProposal("DAO", 0, 1)
            await expect(dao.connect(addr2).voteProposal(1, true))
                .to.emit(dao, "VoteCast")
                .withArgs(addr2.address,1,true);

        });
        it("Ejecutar propuesta", async function(){
            await dao.connect(addr1).createProposal("DAO", 0, 1)
            await dao.connect(addr2).voteProposal(1, true)
            await dao.connect(addr3).voteProposal(1, true)
            await dao.connect(executive1).voteProposal(1, true)
            await expect(dao.connect(owner).executeProposal(1))
                .to.emit(dao, "ProposalExecuted")
                .withArgs(1);
        });

    });

    describe("Eleccion presidente", function () {
        it("El presidente debe poder iniciar una elección", async function () {
            await dao.connect(owner).startElection(1); // Start an election for 1 day
            expect(await dao.isActive()).to.equal(true);

            // Simulate time passing
            await network.provider.send("evm_increaseTime", [86400]);
            await network.provider.send("evm_mine");

            //await dao.connect(owner).endElection();
            //expect(await dao.isActive()).to.equal(false);
        });
        it("Solo los directivos pueden presentarse", async function () {
            await dao.connect(owner).startElection(86400); // 1 día
            await expect(
                dao.connect(addr2).nominateCandidate()
            ).to.be.revertedWith("Solo un directivo puede llamar a esta funcion"); 
            await expect(
                dao.connect(owner).nominateCandidate()
            ).to.be.revertedWith("Solo un directivo puede llamar a esta funcion");         
        });
        it("Para presentarse como candidato la eleccion debe estar activa", async function () {
            await expect(dao.connect(executive1).nominateCandidate())
                .to.be.revertedWith("La eleccion debe estar activa");

        });
        it("El directivo debería poder registrarse", async function () {
            await dao.connect(owner).startElection(1); 
            await expect(dao.connect(executive1).nominateCandidate())
                .to.emit(dao, "CandidateNominated") // Asumiendo que la función emite un evento
                .withArgs(executive1.address);
        });
        it("Los miembros deben poder votar al candidato que deseen", async function(){
            await dao.connect(owner).startElection(1);
            await dao.connect(executive1).nominateCandidate();  
            await expect(dao.connect(addr1).voteElection(0)) //El input es 0 ya que es el 1er candidato y se usa un indice
                .to.emit(dao, "CandidateVoted")
                .withArgs(0);
             
        });
        it("Debe devolver un array vacio en caso de que no haya candidatos", async function(){
            await dao.connect(owner).startElection(1);
            const candidateAddresses = await dao.getCandidateAddresses();
            expect(candidateAddresses.length).to.equal(0);    
        });
        it("Debe incluir a los cantidatos", async function(){
            await dao.connect(owner).startElection(1);
            await dao.connect(executive1).nominateCandidate();
            await dao.connect(executive2).nominateCandidate();

            const candidateAddresses = await dao.getCandidateAddresses();
            expect(candidateAddresses).to.include(executive1.address);
            expect(candidateAddresses).to.include(executive2.address);
            expect(candidateAddresses.length).to.equal(2);    
        });

        it("Debe elegir al nuevo presidente", async function(){
            await dao.connect(owner).startElection(1);
            await dao.connect(executive1).nominateCandidate();
            await dao.connect(executive2).nominateCandidate();
            await dao.connect(addr1).voteElection(1);
            await dao.connect(addr2).voteElection(1);
            await dao.connect(addr3).voteElection(1);

            await network.provider.send("evm_increaseTime", [90000000]);
            await network.provider.send("evm_mine");

            await expect(dao.connect(owner).endElection())
                .to.emit(dao, "ElectionEnded")
                .withArgs(executive2.address);
            
            const memberDetailsExe2 = await dao.getMemberDetails(executive2.address);
            expect(memberDetailsExe2[1]).to.equal(2); //Role presidente esperado

            const memberDetailsOwner = await dao.getMemberDetails(owner.address);
            expect(memberDetailsOwner[1]).to.equal(1); //Role presidente esperado
        });

        


    });

    // Add more tests as needed for other functions
});
