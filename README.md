# TP-2-Blockchain

## Contratos

### Member.sol

El contrato `Member` gestiona los miembros de la organización, sus roles y solicitudes de promoción.

#### Funciones principales

- `addMember(address _member)`: Añade un nuevo miembro a la organización.
- `getMemberDetails(address _member)`: Obtiene los detalles de un miembro específico.
- `initiatePromotion()`: Inicia una solicitud de promoción para el remitente.
- `approvePromotion(address _candidate)`: Aprueba la solicitud de promoción de un miembro.
- `removeMember(address _member)`: Elimina a un miembro de la organización.
- `isMember(address _address)`: Verifica si una dirección es miembro de la organización.
- `totalMembers()`: Devuelve el número total de miembros activos en la organización.

### DAO.sol

El contrato `DAO` gestiona las propuestas y las elecciones dentro de la organización. Hereda del contrato `Member`.

#### Funciones principales

- `startElection(uint256 _duration)`: Inicia una nueva elección de presidente.
- `nominateCandidate()`: Permite a un ejecutivo nominarse como candidato para la elección.
- `voteElection(uint256 candidateIndex)`: Permite a un miembro votar en la elección.
- `endElection()`: Finaliza la elección y asigna el rol de presidente al candidato ganador.
- `createProposal(string memory _description, Category _category, uint256 _duration)`: Crea una nueva propuesta.
- `requestToParticipate(uint256 _proposalId)`: Solicita participar en una propuesta.
- `voteProposal(uint256 _proposalId, bool _support)`: Vota en una propuesta.
- `addTaskToProposal(uint256 _proposalId, string memory _taskDescription, Member.Role _role)`: Añade una tarea a una propuesta.
- `addMemberToTask(uint256 _proposalId, uint256 _id, address _member)`: Asigna un miembro a una tarea de una propuesta.
- `executeTask(uint256 _proposalId, uint256 _id)`: Marca una tarea como completada.
- `approveParticipant(uint256 _proposalId, address _member)`: Aprueba la participación de un miembro en una propuesta.
- `executeProposal(uint256 _proposalId)`: Ejecuta una propuesta si se cumplen las condiciones necesarias.

> Nota: Algunas funciones fueron omitidas para simplificar y poder realizar los tests de manera más eficiente.
