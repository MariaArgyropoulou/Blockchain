// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

contract UniversityGrades {
    address public admin;
    mapping(address => bool) public admins;
    mapping(address => bool) public secretaries;
    mapping(address => bool) public instructors;
    mapping(address => bool) public students;

    // Course details
    struct Course {
        bytes32 name;
        address[] instructors;
        address[] students;
    }

    mapping(uint16 => mapping(bytes32 => Course)) public courses;
    mapping (uint16 => mapping(bytes32 => mapping (address => uint8))) public grades;
    mapping (uint16 => mapping(bytes32 => bool)) public flag; 
    uint256 public gradesDeadline;

    constructor() {
        admin = msg.sender;
        admins[msg.sender] = true;
        // Set a default deadline (unix timestamp) for grade submissions
        gradesDeadline = block.timestamp + 4 weeks;
    }

    // Modifiers used to determine which role can call it's appropriate functions
    modifier onlyAdmin() {require(admins[msg.sender], "Only administrators allowed");_;}
    modifier onlySecretary() {require(secretaries[msg.sender] || admins[msg.sender], "Only secretaries and admins allowed");_;}
    modifier onlyInstructor() {require(instructors[msg.sender], "Only instructors allowed");_;}
    modifier onlyStudent() {require(students[msg.sender], "Only students allowed");_;}

    // Administrator's functions
    function addAdmin(address _newAdmin) external onlyAdmin {admins[_newAdmin] = true;}
    function deleteAdmin(address _admin) external onlyAdmin {admins[_admin] = false;}
    function addSecretary(address _newSecretary) external onlyAdmin {secretaries[_newSecretary] = true;}
    function deleteSecretary(address _secretary) external onlyAdmin {secretaries[_secretary] = false;}

    function addInstructor(address _newInstructor) external onlySecretary {instructors[_newInstructor] = true;}
    function addStudent(address _newStudent) external onlySecretary{students[_newStudent] = true;}
    function deleteInstructor(address _instructor) external onlySecretary {instructors[_instructor] = false;}
    function deleteStudent(address _student) external onlySecretary{students[_student] = false;}

    // Secretary's functions
    // Function to add a course for a specific year
    function createCourse(bytes32 _courseName, uint16 _academicYear) external onlySecretary{
        require(_courseName.length > 0, "Course name can't be empty");
        courses[_academicYear][_courseName] = Course({
            name: _courseName,
            instructors: new address[](0),
            students: new address[](0)});
    }
    
    function enrollInstructor(uint16 _academicYear, address _instructor, bytes32 _courseName ) external onlySecretary{
        courses[_academicYear][_courseName].instructors.push(_instructor);
    }

    function enrollStudent(uint16 _academicYear, address _student, bytes32 _courseName) external onlySecretary{ 
        courses[_academicYear][_courseName].students.push(_student);
        grades[_academicYear][_courseName][_student] = 1;
    }

    function setGrade(uint16 _academicYear, uint8 _grade, address _student, bytes32 _courseName) external onlySecretary{
        require(_courseName.length > 0, "Course name can't be empty");
        require(grades[_academicYear][_courseName][_student] != 0, "Student isn't enrolled yet");
        require(_grade != 0, "Grade can not be 0");
        grades[_academicYear][_courseName][_student] = _grade;   
    }

    function setGradesDeadline(uint256 _deadline) external onlySecretary {
        gradesDeadline = _deadline;
    }

    // Professor's functions
    function getStudents(bytes32 _courseName, uint16 _academicYear) external onlyInstructor view returns (address[] memory){
        require(courses[_academicYear][_courseName].name.length > 0 , "Course does not exist.");
        return courses[_academicYear][_courseName].students;
    }

    function postGrades(bytes32 _courseName, uint16 _academicYear, uint8[] memory _grades) external onlyInstructor{
        require(block.timestamp <= gradesDeadline, "Grade submission deadline passed");
        require(!flag[_academicYear][_courseName],"Grades already posted");
        require(findPerson(courses[_academicYear][_courseName].instructors, msg.sender), "Only the instructor of the course can post grades");
        address _student;
        for ( uint8 i=0; i<courses[_academicYear][_courseName].students.length; i++) 
        {
            _student=courses[_academicYear][_courseName].students[i];
            grades[_academicYear][_courseName][_student]=_grades[i];
        }
        flag[_academicYear][_courseName]=true;

    }

    function findPerson(address[] memory _array, address _person) internal pure returns (bool){
        for (uint i = 0; i < _array.length; i++) {
            if (_array[i] == _person) {
                return true;
            }
        }
        return false; 
    }

    //Student's functions
    function getGrade(uint16 _academicYear, bytes32 _courseName) external onlyStudent view returns (uint8){
        return grades[_academicYear][_courseName][msg.sender];
    }

    /*
    function getGrades(address studentAddress) external view returns (uint256[] memory) {
        
        for (uint256 i = 0; i < courses; i++) {
            grades[i] = grades[_academicyear][i][msg.sender];
        }
    }

    */


}
   
