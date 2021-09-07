// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// Campaign Factory
contract CampaignFactory {
    // Variables
    Campaign[] public deployedCampaigns;

    // Funciones
    /**
     * @notice Función que nos permite crear nuevas campañas.
     * @param _minimum Valor mínimo para poder participar en la campaña.
     */
    function createCampaign(uint _minimum) public {
        Campaign newCampaign = new Campaign(_minimum, msg.sender);
        deployedCampaigns.push(newCampaign);
    }

    /**
     * @notice Función que nos permite ver los contratos de las campañas creadas.
     */
    function getDeployedCampaigns() public view returns(Campaign[] memory) {
        return deployedCampaigns;
    }
}

// Campaign
contract Campaign {
    // Variables
    struct Request{
        string description;
        uint value;
        address payable recipient;
        bool complete;
        uint approvalCount;
        mapping(address => bool) approvals;
    }

    uint numRequests;
    mapping (uint => Request) public requests;
    address public manager;
    uint public minimumContribution;
    mapping(address => bool) public approvers;
    uint public approversCount;

    // Modificadores
    modifier restricted() {
        require(msg.sender == manager, "Debes ser el duenho para crear una solicitud!!");
        _;
    }

    // Constructor
    constructor(uint _minimum, address _creator) {
        manager = _creator;
        minimumContribution = _minimum;
    }

    // Funciones
    /**
     * @notice Permite a la gente contribuir en el proyecto y pasar a formar parte de las decisiones del proyecto.
     */
    function contribute() public payable {
        require(msg.value > minimumContribution, "Debes enviar una cantidad mayor que el minimo.");
        
        approvers[msg.sender] = true;
        approversCount++;
    }

    /**
     * @notice Permite al dueño crear solicitudes para el proyecto.
     * @param _description Descripción de la solicitud.
     * @param _value Cantidad requerida para la solicitud.
     * @param _recipient Dirección a la que se va a mandar el dinero.
     */
    function createRequest(string memory _description, uint _value, address payable _recipient) public restricted {
        Request storage r = requests[numRequests++];
        r.description = _description;
        r.value = _value;
        r.recipient = _recipient;
        r.complete = false;
        r.approvalCount = 0;
    }

    /**
     * @notice Sistema de votación el cual te permite votar sobre una solicitud si estás de acuerdo con ella para llevarla a cabo.
     * @param _index Número de la solicitud que deseamos votar.
     */
    function approveRequest(uint _index) public {
        Request storage request = requests[_index];

        require(approvers[msg.sender], "Debes haber contribuido para poder aprobar una solicitud.");
        require(!request.approvals[msg.sender], "No puedes volver a votar en esta solicitud.");

        request.approvals[msg.sender] = true; // Marca a este usuario como que ya ha votado en este contrato.
        request.approvalCount++; // Incrementa el número de votos en esta solicitud.
    }

    /**
     * @notice Función que completa una solicitud.
     * @param _index Número de la solicitud que deseamos completar.
     */
    function finalizeRequest(uint _index) public restricted {
        Request storage request = requests[_index];
        
        require(request.approvalCount > (approversCount / 2), "No hay suficientes votos positivos para llevar a cabo la solicitud.");
        require(!request.complete, "La solicitud ya ha sido completada.");

        request.recipient.transfer(request.value);
        request.complete = true;
    }
}