pragma solidity 0.4.25 >=0.5.0;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;                                      // Account used to deploy contract
    bool private operational = true;

    mapping(address => bool) private authorizedCaller;                                    // Blocks all state changes throughout the contract if false

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/


    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor
                                (
                                ) 
                                public 
    {
        contractOwner = msg.sender;
        authorizedCaller[contractOwner] = true;
    }

    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
    * @dev Modifier that requires the "operational" boolean variable to be "true"
    *      This is used on all state changing functions to pause the contract in 
    *      the event there is an issue that needs to be fixed
    */
    modifier requireIsOperational() 
    {
        require(operational, "Contract is currently not operational");
        _;  // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier requireContractOwner()
    {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    /**
    * @dev Modifier that requires the "requireCallerAuthorized" account to be the function caller
    */
    modifier requireCallerAuthorized()
    {
        require(authorizedCaller[msg.sender]==true, "Caller is not authorized");
        _;
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    /**
    * @dev Get operating status of contract
    *
    * @return A bool that is the current operating status
    */      
    function isOperational() 
                            public 
                            view 
                            returns(bool) 
    {
        return operational;
    }


    /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    */    
    function setOperatingStatus
                            (
                                bool mode
                            ) 
                            external
                            requireContractOwner 
    {
        operational = mode;
    }

    function authorizeCaller
                            (
                                address _address
                            )
                            external
                            requireIsOperational
                            requireContractOwner 
    {
        authorizedCaller(_address) = true;
    }

    function deauthorizeCaller
                                (
                                    address _address
                                )
                                external
                                requireIsOperational
                                requireContractOwner 
    {
        delete authorizedCaller(_address);
    }
    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

   /**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    */   
    mapping(address => Airline) private airlines;
    uint256 private registeredAirlines = 0;

    struct Airline{
        AirlineStatus status;
        address[] votes;
        uint256 funds;
    } 

    enum AirlineStatus {Nominated, Registered, Funded}

    /**
    * @dev Count Airline Register
    *      Can only be called from FlightSuretyApp contract
    *
    */  
    function registeredAirlineCount
                            (   
                            )
                            external
                            view
                            requireIsOperational
                            requireCallerAuthorized
                            returns (uint256)
    {
        return registeredAirlines;
    }

     /**
    * @dev Number Airline Votes
    *      Can only be called from FlightSuretyApp contract
    *
    */
    function numberAirlineVotes
                            (  
                                address airlineAddress 
                            )
                            external
                            view
                            requireIsOperational
                            requireCallerAuthorized
                            returns (uint256)
    {
        return airlines[airlineAddress].votes.length;
    }

    function amountAirlineFunds
                            (  
                                address airlineAddress 
                            )
                            external
                            view
                            requireIsOperational
                            requireCallerAuthorized
                            returns (uint256)
    {
        return airlines[airlineAddress].funds;
    }

    function isAirlineNominated
                            (  
                                address airlineAddress 
                            )
                            external
                            view
                            requireIsOperational
                            requireCallerAuthorized
                            returns (bool)
    {
        return airlines[airlineAddress].status == AirlineStatus.Nominated;
    }

    function isAirlineRegistered
                            (  
                                address airlineAddress 
                            )
                            external
                            view
                            requireIsOperational
                            requireCallerAuthorized
                            returns (bool)
    {
        return airlines[airlineAddress].status == AirlineStatus.Funded;
    }

    function isAirlineFunded
                            (  
                                address airlineAddress 
                            )
                            external
                            view
                            requireIsOperational
                            requireCallerAuthorized
                            returns (bool)
    {
        return airlines[airlineAddress].status == AirlineStatus.Funded;
    }

    function nominatedAirline
                            (  
                                address airlineAddress 
                            )
                            external
                            requireIsOperational
                            requireCallerAuthorized
    {
        airlines[airlineAddress] = Airline(
            AirlineStatus.Nominated,
            new address[](0),
            0
        );
    }

    function registerAirline
                            (  
                                address airlineAddress 
                            )
                            external
                            requireIsOperational
                            requireCallerAuthorized
                            returns (bool)
    {
        airlines[airlineAddress].status =AirlineStatus.Registered;
        registeredAirlines++;
        return airlines[airlineAddress].status == AirlineStatus.Registered;
    }

    function voteAirline
                            (  
                                address airlineAddress,
                                address voteAddress 
                            )
                            external
                            requireIsOperational
                            requireCallerAuthorized
                            returns (uint256)
    {
        airlines[airlineAddress].votes.push(voteAddress);
        return airlines[airlineAddress].votes.length;
    }

    function fundAirline
                            (  
                                address airlineAddress,
                                uint256 fundingAmount 
                            )
                            external
                            requireIsOperational
                            requireCallerAuthorized
                            returns (uint256)
    {
        airlines[airlineAddress].funds += fundingAmount;
        airlines[airlineAddress].status = AirlineStatus.Funded;
        return airlines[airlineAddress].funds;
    }

    /**
    * @dev Add an flight to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    */  

    struct Flight {
        bool isRegistered;
        address airline;
        string flight;
        uint256 departureTime;
        uint8 statusCode;
        address[] insuress;
    }

    mapping(bytes32 => Flight) private flights;

    function registerFlight
                            (
                                address airline,
                                string flight,
                                uint256 departureTime,
                                uint8 statusCode                             
                            )
                            external
                            requireIsOperational
                            requireCallerAuthorized
    {
        bytes32 key = getFlightKey(airline, flight, departureTime);
        Flight memory newFlight;
        newFlight.isRegistered = true;
        newFlight.airline = airline;
        newFlight.flight = flight;
        newFlight.departureTime = departureTime;
        newFlight.statusCode = statusCode;
        flights[key] = newFlight;
    }

    function updateFlightStatus
                            (  
                                uint8 statusCode,
                                bytes32 flightKey                           
                            )
                            external 
                            requireIsOperational
                            requireCallerAuthorized
    {
        flights[flightKey].statusCode = statusCode;
    }

    function isFlightRegistered
                            (  
                                bytes32 flightKey                           
                            )
                            external
                            view
                            requireIsOperational
                            requireCallerAuthorized
                            returns (bool)
    {
        return flights[flightKey].isRegistered;
    }

    /**
    * @dev Add an Insurance contract to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    */  
    
    struct Insurance{
        uint256 funds;
        bool withdrawable;
    }

    mapping(address => Insurance) private insurance;
   /**
    * @dev Buy insurance for a flight
    *
    */   
    function buy
                            (
                                address passengerAddress,
                                uint256 insuranceAmount, 
                                bytes32 flightKey                             
                            )
                            external
                            requireIsOperational
                            requireCallerAuthorized
    {
        flights[flightKey].insurance.push(passengerAddress);
        Insurance memory newInsurance;
        newInsurance.funds = insuranceAmount;
        newInsurance.withdrawable = false;
        insurance[passengerAddress] = newInsurance; 
    }

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees
                                (
                                    bytes32 flightKey
                                )
                                external
                                requireIsOperational
                                requireCallerAuthorized
    {
        for(uint8 i = 0; i <= flights[flightKey].insurees.length; i++) {
            address passengerAddress = flights[flightKey].insurees[i];
            insurance[passengerAddress].withdrawable = true;
        }
    }
    

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function pay
                            (
                            )
                            external
                            pure
    {
    }

   /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    */   
    function fund
                            (   
                            )
                            public
                            payable
    {
    }

    function getFlightKey
                        (
                            address airline,
                            string memory flight,
                            uint256 timestamp
                        )
                        pure
                        internal
                        returns(bytes32) 
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    /**
    * @dev Fallback function for funding smart contract.
    *
    */
    function() 
                            external 
                            payable 
    {
        fund();
    }


}

