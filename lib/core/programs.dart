import 'package:vias/shared/models/prospectus_models.dart';

List<Program> programs = [
  // Vocational Training Programmes (NVA Level 1-3)
  Program(
    id: '1',
    name: 'Certificate in Footwear and Leather Goods',
    description:
        'A vocational program focusing on the design, production, and maintenance of footwear and leather goods.',
    duration:
        '1 Year (NVA Level 1), 1 Year (NVA Level 2), 1 Year (NVA Level 3)',
    requirements: [
      'Certificate of Secondary Education (CSEE) with at least D grade in two subjects',
    ],
    category: 'Certificate',
    faculty: 'Science and Laboratory Technology (Mwanza Campus)',
    fee: null, // Fee not specified in the provided document
    careerOpportunities: [
      'Leather Goods Artisan',
      'Footwear Designer',
      'Production Technician',
    ],
  ),
  Program(
    id: '2',
    name: 'Certificate in Laboratory Assistant',
    description:
        'A vocational program training students in laboratory techniques and safety procedures.',
    duration:
        '1 Year (NVA Level 1), 1 Year (NVA Level 2), 1 Year (NVA Level 3)',
    requirements: [
      'Certificate of Secondary Education (CSEE) with at least D grade in two subjects',
    ],
    category: 'Certificate',
    faculty: 'Science and Laboratory Technology (Mwanza Campus)',
    fee: null, // Fee not specified in the provided document
    careerOpportunities: [
      'Laboratory Assistant',
      'Quality Control Technician',
      'Research Assistant',
    ],
  ),
  Program(
    id: '3',
    name: 'Certificate in Information and Communication Technology',
    description:
        'A vocational program covering basic ICT skills, computer maintenance, and network fundamentals.',
    duration:
        '1 Year (NVA Level 1), 1 Year (NVA Level 2), 1 Year (NVA Level 3)',
    requirements: [
      'Certificate of Secondary Education (CSEE) with at least D grade in two subjects',
    ],
    category: 'Certificate',
    faculty: 'Science and Laboratory Technology (Mwanza Campus)',
    fee: null, // Fee not specified in the provided document
    careerOpportunities: [
      'IT Support Technician',
      'Network Assistant',
      'Computer Operator',
    ],
  ),
  Program(
    id: '4',
    name: 'Certificate in Plumbing and Pipe Fitting',
    description:
        'A vocational program focusing on plumbing systems, pipe fitting, and maintenance.',
    duration:
        '1 Year (NVA Level 1), 1 Year (NVA Level 2), 1 Year (NVA Level 3)',
    requirements: [
      'Certificate of Secondary Education (CSEE) with at least D grade in two subjects',
    ],
    category: 'Certificate',
    faculty: 'Civil Engineering (Myunga Campus)',
    fee: null, // Fee not specified in the provided document
    careerOpportunities: ['Plumber', 'Pipe Fitter', 'Maintenance Technician'],
  ),

  // Basic Technician Certificate Programmes (NTA Level 4)
  Program(
    id: '5',
    name: 'Basic Technician Certificate in Civil Engineering',
    description:
        'An introductory program covering fundamentals of civil engineering, including construction and technical drawing.',
    duration: '1 Year',
    requirements: [
      'Certificate of Secondary Education (CSEE) with at least D grade in four subjects including Mathematics, Physics/Engineering Science, and Chemistry',
      'OR NVA Level III in a relevant vocational field with at least D grade in two subjects at CSEE',
    ],
    category: 'Basic Technician Certificate',
    faculty: 'Civil Engineering',
    fee: 1300000, // From Table 4.1(b) for private-sponsored students (NTA 4-6)
    careerOpportunities: [
      'Civil Engineering Technician',
      'Construction Assistant',
      'Surveying Assistant',
    ],
  ),
  Program(
    id: '6',
    name: 'Basic Technician Certificate in Electrical Engineering',
    description:
        'A foundational program in electrical engineering, focusing on electrical installations and DC networks.',
    duration: '1 Year',
    requirements: [
      'Certificate of Secondary Education (CSEE) with at least D grade in four subjects including Mathematics, Physics/Engineering Science, and Chemistry',
      'OR NVA Level III in a relevant vocational field with at least D grade in two subjects at CSEE',
    ],
    category: 'Basic Technician Certificate',
    faculty: 'Electrical Engineering',
    fee: 1300000, // From Table 4.1(b) for private-sponsored students (NTA 4-6)
    careerOpportunities: [
      'Electrical Technician',
      'Wiring Installer',
      'Maintenance Technician',
    ],
  ),
  Program(
    id: '7',
    name:
        'Basic Technician Certificate in Electronics and Telecommunication Engineering',
    description:
        'A program introducing electronics and telecommunication principles, including basic electronics and communication systems.',
    duration: '1 Year',
    requirements: [
      'Certificate of Secondary Education (CSEE) with at least D grade in four subjects including Mathematics, Physics/Engineering Science, and Chemistry',
      'OR NVA Level III in a relevant vocational field with at least D grade in two subjects at CSEE',
    ],
    category: 'Basic Technician Certificate',
    faculty: 'Electrical Engineering',
    fee: 1300000, // From Table 4.1(b) for private-sponsored students (NTA 4-6)
    careerOpportunities: [
      'Electronics Technician',
      'Telecommunication Assistant',
      'Network Support Technician',
    ],
  ),
  Program(
    id: '8',
    name: 'Basic Technician Certificate in Communication System Technology',
    description:
        'A program focusing on communication system technologies, including programming and network fundamentals.',
    duration: '1 Year',
    requirements: [
      'Certificate of Secondary Education (CSEE) with at least D grade in four subjects including Mathematics, Physics/Engineering Science, and Chemistry',
      'OR NVA Level III in a relevant vocational field with at least D grade in two subjects at CSEE',
    ],
    category: 'Basic Technician Certificate',
    faculty: 'Electrical Engineering',
    fee: 1300000, // From Table 4.1(b) for private-sponsored students (NTA 4-6)
    careerOpportunities: [
      'Communication Technician',
      'Network Administrator',
      'IT Support Specialist',
    ],
  ),
  Program(
    id: '9',
    name: 'Basic Technician Certificate in Mechanical Engineering',
    description:
        'An introductory program in mechanical engineering, covering engineering drawing and machine tools.',
    duration: '1 Year',
    requirements: [
      'Certificate of Secondary Education (CSEE) with at least D grade in four subjects including Mathematics, Physics/Engineering Science, and Chemistry',
      'OR NVA Level III in a relevant vocational field with at least D grade in two subjects at CSEE',
    ],
    category: 'Basic Technician Certificate',
    faculty: 'Mechanical Engineering',
    fee: 1300000, // From Table 4.1(b) for private-sponsored students (NTA 4-6)
    careerOpportunities: [
      'Mechanical Technician',
      'Machine Operator',
      'Maintenance Assistant',
    ],
  ),
  Program(
    id: '10',
    name: 'Basic Technician Certificate in Science and Laboratory Technology',
    description:
        'A program focusing on laboratory techniques, safety, and basic scientific principles.',
    duration: '1 Year',
    requirements: [
      'Certificate of Secondary Education (CSEE) with at least D grade in four subjects including Mathematics, Physics, and Chemistry',
      'OR NVA Level III in a relevant vocational field with at least D grade in two subjects at CSEE',
    ],
    category: 'Basic Technician Certificate',
    faculty: 'Science and Laboratory Technology',
    fee: 1300000, // From Table 4.1(b) for private-sponsored students (NTA 4-6)
    careerOpportunities: [
      'Laboratory Technician',
      'Quality Control Analyst',
      'Research Assistant',
    ],
  ),
  Program(
    id: '11',
    name: 'Basic Technician Certificate in Food Science and Technology',
    description:
        'A program covering fundamentals of food science, including food chemistry and processing.',
    duration: '1 Year',
    requirements: [
      'Certificate of Secondary Education (CSEE) with at least D grade in four subjects including Mathematics, Physics, and Chemistry',
      'OR NVA Level III in a relevant vocational field with at least D grade in two subjects at CSEE',
    ],
    category: 'Basic Technician Certificate',
    faculty: 'Science and Laboratory Technology',
    fee: 1300000, // From Table 4.1(b) for private-sponsored students (NTA 4-6)
    careerOpportunities: [
      'Food Technician',
      'Quality Assurance Specialist',
      'Food Processing Operator',
    ],
  ),
  Program(
    id: '12',
    name: 'Basic Technician Certificate in Biotechnology',
    description:
        'An introductory program in biotechnology, covering basic organic chemistry and biological principles.',
    duration: '1 Year',
    requirements: [
      'Certificate of Secondary Education (CSEE) with at least D grade in four subjects including Mathematics, Physics, and Chemistry',
      'OR NVA Level III in a relevant vocational field with at least D grade in two subjects at CSEE',
    ],
    category: 'Basic Technician Certificate',
    faculty: 'Science and Laboratory Technology',
    fee: 1300000, // From Table 4.1(b) for private-sponsored students (NTA 4-6)
    careerOpportunities: [
      'Biotechnology Technician',
      'Laboratory Assistant',
      'Research Technician',
    ],
  ),
  Program(
    id: '13',
    name: 'Basic Technician Certificate in Textile Technology',
    description:
        'A program introducing textile technology, focusing on textile production and processing.',
    duration: '1 Year',
    requirements: [
      'Certificate of Secondary Education (CSEE) with at least D grade in four subjects including Mathematics, Physics, and Chemistry',
      'OR NVA Level III in a relevant vocational field with at least D grade in two subjects at CSEE',
    ],
    category: 'Basic Technician Certificate',
    faculty: 'Science and Laboratory Technology',
    fee: 1300000, // From Table 4.1(b) for private-sponsored students (NTA 4-6)
    careerOpportunities: [
      'Textile Technician',
      'Quality Control Specialist',
      'Production Assistant',
    ],
  ),
  Program(
    id: '14',
    name: 'Basic Technician Certificate in Postharvest Technology',
    description:
        'A program focusing on postharvest handling and processing technologies for agricultural products.',
    duration: '1 Year',
    requirements: [
      'Certificate of Secondary Education (CSEE) with at least D grade in four subjects including Mathematics, Physics, and Chemistry',
      'OR NVA Level III in a relevant vocational field with at least D grade in two subjects at CSEE',
    ],
    category: 'Basic Technician Certificate',
    faculty: 'Science and Laboratory Technology',
    fee: 1300000, // From Table 4.1(b) for private-sponsored students (NTA 4-6)
    careerOpportunities: [
      'Postharvest Technician',
      'Agricultural Processor',
      'Quality Control Specialist',
    ],
  ),
  Program(
    id: '15',
    name: 'Basic Technician Certificate in Multimedia and Film Technology',
    description:
        'A program covering multimedia production, photography, and digital imaging.',
    duration: '1 Year',
    requirements: [
      'Certificate of Secondary Education (CSEE) with at least D grade in four subjects including Mathematics, Physics/Engineering Science, and Chemistry',
      'OR NVA Level III in a relevant vocational field with at least D grade in two subjects at CSEE',
    ],
    category: 'Basic Technician Certificate',
    faculty: 'Computer Studies',
    fee: 1300000, // From Table 4.1(b) for private-sponsored students (NTA 4-6)
    careerOpportunities: [
      'Multimedia Producer',
      'Film Technician',
      'Digital Content Creator',
    ],
  ),
  Program(
    id: '16',
    name: 'Basic Technician Certificate in Information Technology',
    description:
        'A foundational program in IT, covering computer basics, programming, and system maintenance.',
    duration: '1 Year',
    requirements: [
      'Certificate of Secondary Education (CSEE) with at least D grade in four subjects including Mathematics, Physics/Engineering Science, and Chemistry',
      'OR NVA Level III in a relevant vocational field with at least D grade in two subjects at CSEE',
    ],
    category: 'Basic Technician Certificate',
    faculty: 'Computer Studies',
    fee: 1300000, // From Table 4.1(b) for private-sponsored students (NTA 4-6)
    careerOpportunities: [
      'IT Support Technician',
      'System Administrator',
      'Network Assistant',
    ],
  ),
  Program(
    id: '17',
    name: 'Basic Technician Certificate in Biomedical Equipment Engineering',
    description:
        'A program focusing on the maintenance and repair of biomedical equipment.',
    duration: '1 Year',
    requirements: [
      'Certificate of Secondary Education (CSEE) with at least D grade in four subjects including Mathematics, Physics/Engineering Science, and Chemistry',
      'OR NVA Level III in a relevant vocational field with at least D grade in two subjects at CSEE',
    ],
    category: 'Basic Technician Certificate',
    faculty: 'Electrical Engineering',
    fee: 1300000, // From Table 4.1(b) for private-sponsored students (NTA 4-6)
    careerOpportunities: [
      'Biomedical Equipment Technician',
      'Medical Device Repair Specialist',
      'Healthcare Technology Support',
    ],
  ),
  Program(
    id: '18',
    name: 'Basic Technician Certificate in Leather Goods Technology',
    description:
        'A program focusing on the production and technology of leather goods.',
    duration: '1 Year',
    requirements: [
      'Certificate of Secondary Education (CSEE) with at least D grade in four subjects including Mathematics, Physics, and Chemistry',
      'OR NVA Level III in a relevant vocational field with at least D grade in two subjects at CSEE',
    ],
    category: 'Basic Technician Certificate',
    faculty: 'Science and Laboratory Technology (Mwanza Campus)',
    fee: 1300000, // From Table 4.1(b) for private-sponsored students (NTA 4-6)
    careerOpportunities: [
      'Leather Goods Technician',
      'Production Supervisor',
      'Quality Control Specialist',
    ],
  ),
  Program(
    id: '19',
    name: 'Basic Technician Certificate in Leather Processing Technology',
    description:
        'A program covering the fundamentals of leather processing and biochemistry.',
    duration: '1 Year',
    requirements: [
      'Certificate of Secondary Education (CSEE) with at least D grade in four subjects including Mathematics, Physics, and Chemistry',
      'OR NVA Level III in a relevant vocational field with at least D grade in two subjects at CSEE',
    ],
    category: 'Basic Technician Certificate',
    faculty: 'Science and Laboratory Technology (Mwanza Campus)',
    fee: 1300000, // From Table 4.1(b) for private-sponsored students (NTA 4-6)
    careerOpportunities: [
      'Leather Processing Technician',
      'Tannery Operator',
      'Quality Assurance Specialist',
    ],
  ),
  Program(
    id: '20',
    name: 'Basic Technician Certificate in Food Processing Technology',
    description:
        'A program focusing on food processing techniques and food chemistry.',
    duration: '1 Year',
    requirements: [
      'Certificate of Secondary Education (CSEE) with at least D grade in four subjects including Mathematics, Physics, and Chemistry',
      'OR NVA Level III in a relevant vocational field with at least D grade in two subjects at CSEE',
    ],
    category: 'Basic Technician Certificate',
    faculty: 'Science and Laboratory Technology (Mwanza Campus)',
    fee: 1300000, // From Table 4.1(b) for private-sponsored students (NTA 4-6)
    careerOpportunities: [
      'Food Processing Technician',
      'Quality Control Analyst',
      'Food Production Supervisor',
    ],
  ),

  // Technician Certificate Programmes (NTA Level 5)
  Program(
    id: '21',
    name: 'Technician Certificate in Civil Engineering',
    description:
        'A program building on basic civil engineering skills, including hydraulics and structural design.',
    duration: '1 Year',
    requirements: [
      'Basic Technician Certificate (NTA Level 4) in Civil Engineering',
      'OR equivalent qualifications as per NACTVET regulations',
    ],
    category: 'Technician Certificate',
    faculty: 'Civil Engineering',
    fee: 1300000, // From Table 4.1(b) for private-sponsored students (NTA 4-6)
    careerOpportunities: [
      'Civil Engineering Technician',
      'Construction Supervisor',
      'Surveying Technician',
    ],
  ),
  Program(
    id: '22',
    name: 'Technician Certificate in Electrical Engineering',
    description:
        'A program advancing skills in electrical engineering, including digital electronics and control circuits.',
    duration: '1 Year',
    requirements: [
      'Basic Technician Certificate (NTA Level 4) in Electrical Engineering',
      'OR equivalent qualifications as per NACTVET regulations',
    ],
    category: 'Technician Certificate',
    faculty: 'Electrical Engineering',
    fee: 1300000, // From Table 4.1(b) for private-sponsored students (NTA 4-6)
    careerOpportunities: [
      'Electrical Engineering Technician',
      'Control Systems Technician',
      'Maintenance Engineer',
    ],
  ),
  Program(
    id: '23',
    name:
        'Technician Certificate in Electronics and Telecommunication Engineering',
    description:
        'A program focusing on advanced electronics and telecommunication systems.',
    duration: '1 Year',
    requirements: [
      'Basic Technician Certificate (NTA Level 4) in Electronics and Telecommunication Engineering',
      'OR equivalent qualifications as per NACTVET regulations',
    ],
    category: 'Technician Certificate',
    faculty: 'Electrical Engineering',
    fee: 1300000, // From Table 4.1(b) for private-sponsored students (NTA 4-6)
    careerOpportunities: [
      'Electronics Engineer',
      'Telecommunication Technician',
      'Network Engineer',
    ],
  ),
  Program(
    id: '24',
    name: 'Technician Certificate in Communication System Technology',
    description:
        'A program advancing skills in communication systems, including database management and network administration.',
    duration: '1 Year',
    requirements: [
      'Basic Technician Certificate (NTA Level 4) in Communication System Technology',
      'OR equivalent qualifications as per NACTVET regulations',
    ],
    category: 'Technician Certificate',
    faculty: 'Electrical Engineering',
    fee: 1300000, // From Table 4.1(b) for private-sponsored students (NTA 4-6)
    careerOpportunities: [
      'Communication Systems Technician',
      'Network Administrator',
      'IT Specialist',
    ],
  ),
  Program(
    id: '25',
    name: 'Technician Certificate in Mechanical Engineering',
    description:
        'A program covering advanced mechanical engineering topics, including pneumatics and production technology.',
    duration: '1 Year',
    requirements: [
      'Basic Technician Certificate (NTA Level 4) in Mechanical Engineering',
      'OR equivalent qualifications as per NACTVET regulations',
    ],
    category: 'Technician Certificate',
    faculty: 'Mechanical Engineering',
    fee: 1300000, // From Table 4.1(b) for private-sponsored students (NTA 4-6)
    careerOpportunities: [
      'Mechanical Engineering Technician',
      'Production Supervisor',
      'Maintenance Engineer',
    ],
  ),
  Program(
    id: '26',
    name: 'Technician Certificate in Science and Laboratory Technology',
    description:
        'A program advancing laboratory techniques, including inorganic chemistry and applied mechanics.',
    duration: '1 Year',
    requirements: [
      'Basic Technician Certificate (NTA Level 4) in Science and Laboratory Technology',
      'OR equivalent qualifications as per NACTVET regulations',
    ],
    category: 'Technician Certificate',
    faculty: 'Science and Laboratory Technology',
    fee: 1300000, // From Table 4.1(b) for private-sponsored students (NTA 4-6)
    careerOpportunities: [
      'Laboratory Technologist',
      'Quality Assurance Specialist',
      'Research Technician',
    ],
  ),
  Program(
    id: '27',
    name: 'Technician Certificate in Food Science and Technology',
    description:
        'A program focusing on advanced food processing and analysis techniques.',
    duration: '1 Year',
    requirements: [
      'Basic Technician Certificate (NTA Level 4) in Food Science and Technology',
      'OR equivalent qualifications as per NACTVET regulations',
    ],
    category: 'Technician Certificate',
    faculty: 'Science and Laboratory Technology',
    fee: 1300000, // From Table 4.1(b) for private-sponsored students (NTA 4-6)
    careerOpportunities: [
      'Food Technologist',
      'Quality Control Manager',
      'Food Safety Inspector',
    ],
  ),
  Program(
    id: '28',
    name: 'Technician Certificate in Biotechnology',
    description:
        'A program advancing skills in biotechnology, including industrial biotechnology and fermentation.',
    duration: '1 Year',
    requirements: [
      'Basic Technician Certificate (NTA Level 4) in Biotechnology',
      'OR equivalent qualifications as per NACTVET regulations',
    ],
    category: 'Technician Certificate',
    faculty: 'Science and Laboratory Technology',
    fee: 1300000, // From Table 4.1(b) for private-sponsored students (NTA 4-6)
    careerOpportunities: [
      'Biotechnologist',
      'Research Technician',
      'Quality Control Analyst',
    ],
  ),
  Program(
    id: '29',
    name: 'Technician Certificate in Leather Goods Technology',
    description:
        'A program advancing skills in leather goods production and technology.',
    duration: '1 Year',
    requirements: [
      'Basic Technician Certificate (NTA Level 4) in Leather Goods Technology',
      'OR equivalent qualifications as per NACTVET regulations',
    ],
    category: 'Technician Certificate',
    faculty: 'Science and Laboratory Technology (Mwanza Campus)',
    fee: 1300000, // From Table 4.1(b) for private-sponsored students (NTA 4-6)
    careerOpportunities: [
      'Leather Goods Production Supervisor',
      'Quality Control Specialist',
      'Leather Technician',
    ],
  ),
  Program(
    id: '30',
    name: 'Technician Certificate in Leather Processing Technology',
    description:
        'A program focusing on advanced leather processing techniques and quality analysis.',
    duration: '1 Year',
    requirements: [
      'Basic Technician Certificate (NTA Level 4) in Leather Processing Technology',
      'OR equivalent qualifications as per NACTVET regulations',
    ],
    category: 'Technician Certificate',
    faculty: 'Science and Laboratory Technology (Mwanza Campus)',
    fee: 1300000, // From Table 4.1(b) for private-sponsored students (NTA 4-6)
    careerOpportunities: [
      'Leather Processing Technologist',
      'Tannery Supervisor',
      'Quality Assurance Specialist',
    ],
  ),
  Program(
    id: '31',
    name: 'Technician Certificate in Food Processing Technology',
    description:
        'A program advancing skills in food processing, including analysis and instrumentation.',
    duration: '1 Year',
    requirements: [
      'Basic Technician Certificate (NTA Level 4) in Food Processing Technology',
      'OR equivalent qualifications as per NACTVET regulations',
    ],
    category: 'Technician Certificate',
    faculty: 'Science and Laboratory Technology (Mwanza Campus)',
    fee: 1300000, // From Table 4.1(b) for private-sponsored students (NTA 4-6)
    careerOpportunities: [
      'Food Processing Technologist',
      'Quality Control Manager',
      'Food Production Supervisor',
    ],
  ),
  Program(
    id: '32',
    name: 'Technician Certificate in Multimedia and Film Technology',
    description:
        'A program advancing skills in multimedia production, including video and game design.',
    duration: '1 Year',
    requirements: [
      'Basic Technician Certificate (NTA Level 4) in Multimedia and Film Technology',
      'OR equivalent qualifications as per NACTVET regulations',
    ],
    category: 'Technician Certificate',
    faculty: 'Computer Studies',
    fee: 1300000, // From Table 4.1(b) for private-sponsored students (NTA 4-6)
    careerOpportunities: [
      'Multimedia Producer',
      'Film Editor',
      'Game Designer',
    ],
  ),
  Program(
    id: '33',
    name: 'Technician Certificate in Information Technology',
    description:
        'A program advancing IT skills, including event-driven programming and operating systems.',
    duration: '1 Year',
    requirements: [
      'Basic Technician Certificate (NTA Level 4) in Information Technology',
      'OR equivalent qualifications as per NACTVET regulations',
    ],
    category: 'Technician Certificate',
    faculty: 'Computer Studies',
    fee: 1300000, // From Table 4.1(b) for private-sponsored students (NTA 4-6)
    careerOpportunities: [
      'IT Specialist',
      'System Administrator',
      'Software Support Technician',
    ],
  ),
  Program(
    id: '34',
    name: 'Technician Certificate in Biomedical Equipment Engineering',
    description:
        'A program focusing on advanced maintenance and repair of biomedical equipment.',
    duration: '1 Year',
    requirements: [
      'Basic Technician Certificate (NTA Level 4) in Biomedical Equipment Engineering',
      'OR equivalent qualifications as per NACTVET regulations',
    ],
    category: 'Technician Certificate',
    faculty: 'Electrical Engineering',
    fee: 1300000, // From Table 4.1(b) for private-sponsored students (NTA 4-6)
    careerOpportunities: [
      'Biomedical Equipment Technologist',
      'Medical Device Specialist',
      'Healthcare Technology Manager',
    ],
  ),

  // Ordinary Diploma Programmes (NTA Level 6)
  Program(
    id: '35',
    name: 'Ordinary Diploma in Civil Engineering',
    description:
        'A comprehensive diploma program covering advanced civil engineering topics like reinforced concrete design and highway engineering.',
    duration: '1 Year',
    requirements: [
      'Technician Certificate (NTA Level 5) in Civil Engineering',
      'OR equivalent qualifications as per NACTVET regulations',
    ],
    category: 'Ordinary Diploma',
    faculty: 'Civil Engineering',
    fee: 1300000, // From Table 4.1(b) for private-sponsored students (NTA 4-6)
    careerOpportunities: [
      'Civil Engineer',
      'Construction Manager',
      'Structural Designer',
    ],
  ),
  Program(
    id: '36',
    name: 'Ordinary Diploma in Electrical Engineering',
    description:
        'A diploma program focusing on advanced electrical engineering, including power systems and control engineering.',
    duration: '1 Year',
    requirements: [
      'Technician Certificate (NTA Level 5) in Electrical Engineering',
      'OR equivalent qualifications as per NACTVET regulations',
    ],
    category: 'Ordinary Diploma',
    faculty: 'Electrical Engineering',
    fee: 1300000, // From Table 4.1(b) for private-sponsored students (NTA 4-6)
    careerOpportunities: [
      'Electrical Engineer',
      'Power Systems Technician',
      'Control Systems Engineer',
    ],
  ),
  Program(
    id: '37',
    name: 'Ordinary Diploma in Electronics and Telecommunication Engineering',
    description:
        'A diploma program covering advanced electronics and telecommunication systems, including project realization.',
    duration: '1 Year',
    requirements: [
      'Technician Certificate (NTA Level 5) in Electronics and Telecommunication Engineering',
      'OR equivalent qualifications as per NACTVET regulations',
    ],
    category: 'Ordinary Diploma',
    faculty: 'Electrical Engineering',
    fee: 1300000, // From Table 4.1(b) for private-sponsored students (NTA 4-6)
    careerOpportunities: [
      'Electronics Engineer',
      'Telecommunication Engineer',
      'Network Specialist',
    ],
  ),
  Program(
    id: '38',
    name: 'Ordinary Diploma in Communication System Technology',
    description:
        'A diploma program advancing skills in communication systems, including network design and management.',
    duration: '1 Year',
    requirements: [
      'Technician Certificate (NTA Level 5) in Communication System Technology',
      'OR equivalent qualifications as per NACTVET regulations',
    ],
    category: 'Ordinary Diploma',
    faculty: 'Electrical Engineering',
    fee: 1300000, // From Table 4.1(b) for private-sponsored students (NTA 4-6)
    careerOpportunities: [
      'Communication Systems Engineer',
      'Network Manager',
      'IT Consultant',
    ],
  ),
  Program(
    id: '39',
    name: 'Ordinary Diploma in Mechanical Engineering',
    description:
        'A diploma program covering advanced mechanical engineering topics, including production technology and project conceptualization.',
    duration: '1 Year',
    requirements: [
      'Technician Certificate (NTA Level 5) in Mechanical Engineering',
      'OR equivalent qualifications as per NACTVET regulations',
    ],
    category: 'Ordinary Diploma',
    faculty: 'Mechanical Engineering',
    fee: 1300000, // From Table 4.1(b) for private-sponsored students (NTA 4-6)
    careerOpportunities: [
      'Mechanical Engineer',
      'Production Engineer',
      'Maintenance Manager',
    ],
  ),
  Program(
    id: '40',
    name: 'Ordinary Diploma in Science and Laboratory Technology',
    description:
        'A diploma program focusing on advanced laboratory techniques, including modern nuclear physics and project realization.',
    duration: '1 Year',
    requirements: [
      'Technician Certificate (NTA Level 5) in Science and Laboratory Technology',
      'OR equivalent qualifications as per NACTVET regulations',
    ],
    category: 'Ordinary Diploma',
    faculty: 'Science and Laboratory Technology',
    fee: 1300000, // From Table 4.1(b) for private-sponsored students (NTA 4-6)
    careerOpportunities: [
      'Laboratory Manager',
      'Research Scientist',
      'Quality Control Supervisor',
    ],
  ),
  Program(
    id: '41',
    name: 'Ordinary Diploma in Food Science and Technology',
    description:
        'A diploma program covering advanced food science topics, including food analysis and research project development.',
    duration: '1 Year',
    requirements: [
      'Technician Certificate (NTA Level 5) in Food Science and Technology',
      'OR equivalent qualifications as per NACTVET regulations',
    ],
    category: 'Ordinary Diploma',
    faculty: 'Science and Laboratory Technology',
    fee: 1300000, // From Table 4.1(b) for private-sponsored students (NTA 4-6)
    careerOpportunities: [
      'Food Scientist',
      'Quality Assurance Manager',
      'Food Safety Specialist',
    ],
  ),
  Program(
    id: '42',
    name: 'Ordinary Diploma in Biotechnology',
    description:
        'A diploma program advancing biotechnology skills, including bioprocess technology and research projects.',
    duration: '1 Year',
    requirements: [
      'Technician Certificate (NTA Level 5) in Biotechnology',
      'OR equivalent qualifications as per NACTVET regulations',
    ],
    category: 'Ordinary Diploma',
    faculty: 'Science and Laboratory Technology',
    fee: 1300000, // From Table 4.1(b) for private-sponsored students (NTA 4-6)
    careerOpportunities: [
      'Biotechnologist',
      'Research Scientist',
      'Bioprocess Engineer',
    ],
  ),
  Program(
    id: '43',
    name: 'Ordinary Diploma in Leather Goods Technology',
    description:
        'A diploma program focusing on advanced leather goods production and technology.',
    duration: '1 Year',
    requirements: [
      'Technician Certificate (NTA Level 5) in Leather Goods Technology',
      'OR equivalent qualifications as per NACTVET regulations',
    ],
    category: 'Ordinary Diploma',
    faculty: 'Science and Laboratory Technology (Mwanza Campus)',
    fee: 1300000, // From Table 4.1(b) for private-sponsored students (NTA 4-6)
    careerOpportunities: [
      'Leather Goods Production Manager',
      'Quality Assurance Specialist',
      'Leather Technologist',
    ],
  ),
  Program(
    id: '44',
    name: 'Ordinary Diploma in Leather Processing Technology',
    description:
        'A diploma program covering advanced leather processing techniques and quality analysis.',
    duration: '1 Year',
    requirements: [
      'Technician Certificate (NTA Level 5) in Leather Processing Technology',
      'OR equivalent qualifications as per NACTVET regulations',
    ],
    category: 'Ordinary Diploma',
    faculty: 'Science and Laboratory Technology (Mwanza Campus)',
    fee: 1300000, // From Table 4.1(b) for private-sponsored students (NTA 4-6)
    careerOpportunities: [
      'Leather Processing Engineer',
      'Tannery Manager',
      'Quality Control Specialist',
    ],
  ),
  Program(
    id: '45',
    name: 'Ordinary Diploma in Food Processing Technology',
    description:
        'A diploma program focusing on advanced food processing techniques and project realization.',
    duration: '1 Year',
    requirements: [
      'Technician Certificate (NTA Level 5) in Food Processing Technology',
      'OR equivalent qualifications as per NACTVET regulations',
    ],
    category: 'Ordinary Diploma',
    faculty: 'Science and Laboratory Technology (Mwanza Campus)',
    fee: 1300000, // From Table 4.1(b) for private-sponsored students (NTA 4-6)
    careerOpportunities: [
      'Food Processing Engineer',
      'Quality Control Manager',
      'Food Production Manager',
    ],
  ),
  Program(
    id: '46',
    name: 'Ordinary Diploma in Multimedia and Film Technology',
    description:
        'A diploma program covering advanced multimedia and film production, including visual effects and advertisement production.',
    duration: '1 Year',
    requirements: [
      'Technician Certificate (NTA Level 5) in Multimedia and Film Technology',
      'OR equivalent qualifications as per NACTVET regulations',
    ],
    category: 'Ordinary Diploma',
    faculty: 'Computer Studies',
    fee: 1300000, // From Table 4.1(b) for private-sponsored students (NTA 4-6)
    careerOpportunities: [
      'Film Producer',
      'Multimedia Specialist',
      'Visual Effects Artist',
    ],
  ),
  Program(
    id: '47',
    name: 'Ordinary Diploma in Information Technology',
    description:
        'A diploma program advancing IT skills, including system analysis and project conceptualization.',
    duration: '1 Year',
    requirements: [
      'Technician Certificate (NTA Level 5) in Information Technology',
      'OR equivalent qualifications as per NACTVET regulations',
    ],
    category: 'Ordinary Diploma',
    faculty: 'Computer Studies',
    fee: 1300000, // From Table 4.1(b) for private-sponsored students (NTA 4-6)
    careerOpportunities: [
      'IT Consultant',
      'System Analyst',
      'Software Developer',
    ],
  ),
  Program(
    id: '48',
    name: 'Ordinary Diploma in Biomedical Equipment Engineering',
    description:
        'A diploma program focusing on advanced biomedical equipment maintenance and repair.',
    duration: '1 Year',
    requirements: [
      'Technician Certificate (NTA Level 5) in Biomedical Equipment Engineering',
      'OR equivalent qualifications as per NACTVET regulations',
    ],
    category: 'Ordinary Diploma',
    faculty: 'Electrical Engineering',
    fee: 1300000, // From Table 4.1(b) for private-sponsored students (NTA 4-6)
    careerOpportunities: [
      'Biomedical Engineer',
      'Medical Equipment Manager',
      'Healthcare Technology Specialist',
    ],
  ),
  Program(
    id: '49',
    name: 'Ordinary Diploma in Mining Engineering',
    description:
        'A diploma program covering mining engineering principles, including mine supervision and material handling.',
    duration: '1 Year',
    requirements: [
      'Technician Certificate (NTA Level 5) in Mining Engineering',
      'OR equivalent qualifications as per NACTVET regulations',
    ],
    category: 'Ordinary Diploma',
    faculty: 'Civil Engineering',
    fee: 1300000, // From Table 4.1(b) for private-sponsored students (NTA 4-6)
    careerOpportunities: [
      'Mining Engineer',
      'Mine Supervisor',
      'Geotechnical Technician',
    ],
  ),

  // Higher Diploma Programmes (NTA Level 7)
  Program(
    id: '50',
    name: 'Higher Diploma in Civil Engineering',
    description:
        'An advanced program covering civil engineering topics like highway engineering and foundation design.',
    duration: '2-3 Years',
    requirements: [
      'Ordinary Diploma (NTA Level 6) in Civil Engineering with a minimum GPA of 3.0',
      'OR Full Technician Certificate (FTC) in a relevant field with a minimum of C grade',
    ],
    category: 'Higher Diploma',
    faculty: 'Civil Engineering',
    fee: 1500000, // From Table 4.2(a) for private-sponsored students (NTA 7-8)
    careerOpportunities: [
      'Senior Civil Engineer',
      'Project Manager',
      'Structural Engineer',
    ],
  ),
  Program(
    id: '51',
    name: 'Higher Diploma in Electrical Engineering',
    description:
        'An advanced program focusing on electrical power systems, transmission, and distribution.',
    duration: '2-3 Years',
    requirements: [
      'Ordinary Diploma (NTA Level 6) in Electrical Engineering with a minimum GPA of 3.0',
      'OR Full Technician Certificate (FTC) in a relevant field with a minimum of C grade',
    ],
    category: 'Higher Diploma',
    faculty: 'Electrical Engineering',
    fee: 1500000, // From Table 4.2(a) for private-sponsored students (NTA 7-8)
    careerOpportunities: [
      'Senior Electrical Engineer',
      'Power Systems Engineer',
      'Electrical Project Manager',
    ],
  ),
  Program(
    id: '52',
    name: 'Higher Diploma in Electronics and Telecommunication Engineering',
    description:
        'An advanced program covering electronics, telecommunication systems, and sensor networks.',
    duration: '2-3 Years',
    requirements: [
      'Ordinary Diploma (NTA Level 6) in Electronics and Telecommunication Engineering with a minimum GPA of 3.0',
      'OR Full Technician Certificate (FTC) in a relevant field with a minimum of C grade',
    ],
    category: 'Higher Diploma',
    faculty: 'Electrical Engineering',
    fee: 1500000, // From Table 4.2(a) for private-sponsored students (NTA 7-8)
    careerOpportunities: [
      'Telecommunication Engineer',
      'Electronics Specialist',
      'Network Systems Manager',
    ],
  ),
  Program(
    id: '53',
    name: 'Higher Diploma in Computer Engineering',
    description:
        'An advanced program focusing on computer engineering, including sensor networks and programming.',
    duration: '2-3 Years',
    requirements: [
      'Ordinary Diploma (NTA Level 6) in Computer Engineering or Information Technology with a minimum GPA of 3.0',
      'OR Full Technician Certificate (FTC) in a relevant field with a minimum of C grade',
    ],
    category: 'Higher Diploma',
    faculty: 'Computer Studies',
    fee: 1500000, // From Table 4.2(a) for private-sponsored students (NTA 7-8)
    careerOpportunities: [
      'Computer Engineer',
      'Software Engineer',
      'Systems Developer',
    ],
  ),
  Program(
    id: '54',
    name: 'Higher Diploma in Biomedical Engineering',
    description:
        'An advanced program focusing on biomedical engineering, including medical equipment maintenance and circuit analysis.',
    duration: '2-3 Years',
    requirements: [
      'Ordinary Diploma (NTA Level 6) in Biomedical Equipment Engineering with a minimum GPA of 3.0',
      'OR Full Technician Certificate (FTC) in a relevant field with a minimum of C grade',
    ],
    category: 'Higher Diploma',
    faculty: 'Electrical Engineering',
    fee: 1500000, // From Table 4.2(a) for private-sponsored students (NTA 7-8)
    careerOpportunities: [
      'Biomedical Engineer',
      'Medical Equipment Specialist',
      'Healthcare Technology Manager',
    ],
  ),

  // Bachelor Degree Programmes (NTA Level 8)
  Program(
    id: '55',
    name: 'Bachelor of Engineering in Civil Engineering',
    description:
        'A comprehensive program covering advanced civil engineering topics, including foundation engineering and industrial building construction.',
    duration: '1 Year (NTA 8, following NTA 7)',
    requirements: [
      'Higher Diploma (NTA Level 7) in Civil Engineering with a minimum GPA of 3.0',
      'OR equivalent qualifications with a minimum of three years of working experience',
    ],
    category: 'Bachelor',
    faculty: 'Civil Engineering',
    fee: 1500000, // From Table 4.2(a) for private-sponsored students (NTA 7-8)
    careerOpportunities: [
      'Civil Engineer',
      'Construction Manager',
      'Structural Engineer',
    ],
  ),
  Program(
    id: '56',
    name: 'Bachelor of Engineering in Electrical Engineering',
    description:
        'A comprehensive program focusing on advanced electrical engineering, including power plant and transmission systems.',
    duration: '1 Year (NTA 8, following NTA 7)',
    requirements: [
      'Higher Diploma (NTA Level 7) in Electrical Engineering with a minimum GPA of 3.0',
      'OR equivalent qualifications with a minimum of three years of working experience',
    ],
    category: 'Bachelor',
    faculty: 'Electrical Engineering',
    fee: 1500000, // From Table 4.2(a) for private-sponsored students (NTA 7-8)
    careerOpportunities: [
      'Electrical Engineer',
      'Power Systems Manager',
      'Control Systems Engineer',
    ],
  ),
  Program(
    id: '57',
    name:
        'Bachelor of Engineering in Electronics and Telecommunication Engineering',
    description:
        'A comprehensive program covering advanced electronics and telecommunication systems, including radar and broadcasting engineering.',
    duration: '1 Year (NTA 8, following NTA 7)',
    requirements: [
      'Higher Diploma (NTA Level 7) in Electronics and Telecommunication Engineering with a minimum GPA of 3.0',
      'OR equivalent qualifications with a minimum of three years of working experience',
    ],
    category: 'Bachelor',
    faculty: 'Electrical Engineering',
    fee: 1500000, // From Table 4.2(a) for private-sponsored students (NTA 7-8)
    careerOpportunities: [
      'Telecommunication Engineer',
      'Electronics Engineer',
      'Broadcasting Specialist',
    ],
  ),
  Program(
    id: '58',
    name: 'Bachelor of Engineering in Computer Engineering',
    description:
        'A comprehensive program covering advanced computer engineering topics, including real-time systems and project realization.',
    duration: '1 Year (NTA 8, following NTA 7)',
    requirements: [
      'Higher Diploma (NTA Level 7) in Computer Engineering with a minimum GPA of 3.0',
      'OR equivalent qualifications with a minimum of three years of working experience',
    ],
    category: 'Bachelor',
    faculty: 'Computer Studies',
    fee: 1500000, // From Table 4.2(a) for private-sponsored students (NTA 7-8)
    careerOpportunities: [
      'Computer Engineer',
      'Software Developer',
      'Systems Analyst',
    ],
  ),
  Program(
    id: '59',
    name: 'Bachelor of Engineering in Biomedical Engineering',
    description:
        'A comprehensive program focusing on advanced biomedical engineering, including medical equipment maintenance and project realization.',
    duration: '1 Year (NTA 8, following NTA 7)',
    requirements: [
      'Higher Diploma (NTA Level 7) in Biomedical Engineering with a minimum GPA of 3.0',
      'OR equivalent qualifications with a minimum of three years of working experience',
    ],
    category: 'Bachelor',
    faculty: 'Electrical Engineering',
    fee: 1500000, // From Table 4.2(a) for private-sponsored students (NTA 7-8)
    careerOpportunities: [
      'Biomedical Engineer',
      'Healthcare Technology Manager',
      'Medical Device Engineer',
    ],
  ),
  Program(
    id: '60',
    name: 'Bachelor of Engineering in Oil and Gas Engineering',
    description:
        'A comprehensive program covering oil and gas processing, distribution, and safety systems.',
    duration: '1 Year (NTA 8, following NTA 7)',
    requirements: [
      'Higher Diploma (NTA Level 7) in a relevant engineering field with a minimum GPA of 3.0',
      'OR equivalent qualifications with a minimum of three years of working experience',
    ],
    category: 'Bachelor',
    faculty: 'Mechanical Engineering',
    fee: 1500000, // From Table 4.2(a) for private-sponsored students (NTA 7-8)
    careerOpportunities: [
      'Oil and Gas Engineer',
      'Petroleum Engineer',
      'Safety Manager',
    ],
  ),
  Program(
    id: '61',
    name: 'Bachelor of Engineering in Mining Engineering',
    description:
        'A comprehensive program focusing on mining engineering, including mine planning and material handling.',
    duration: '1 Year (NTA 8, following NTA 7)',
    requirements: [
      'Higher Diploma (NTA Level 7) in Mining Engineering with a minimum GPA of 3.0',
      'OR equivalent qualifications with a minimum of three years of working experience',
    ],
    category: 'Bachelor',
    faculty: 'Civil Engineering',
    fee: 1500000, // From Table 4.2(a) for private-sponsored students (NTA 7-8)
    careerOpportunities: [
      'Mining Engineer',
      'Geotechnical Engineer',
      'Mine Operations Manager',
    ],
  ),

  // Master’s Programmes (NTA Level 9)
  Program(
    id: '62',
    name: 'Master of Engineering in Maintenance Management',
    description:
        'A postgraduate program focusing on maintenance management strategies and engineering practices.',
    duration: '18 Months',
    requirements: [
      'Bachelor’s degree in Engineering or Science in related fields with a GPA of at least 2.7',
      'OR a pass with a minimum of three years of working experience',
    ],
    category: 'Master',
    faculty: 'Mechanical Engineering',
    fee: 3585400, // From Table 4.3(a) for Tanzanian students (Semester I)
    careerOpportunities: [
      'Maintenance Manager',
      'Engineering Consultant',
      'Operations Manager',
    ],
  ),
  Program(
    id: '63',
    name: 'Master of Technology in Computing and Communication',
    description:
        'A postgraduate program covering advanced topics in computing and communication, including big data analytics and cybersecurity.',
    duration: '18 Months',
    requirements: [
      'Bachelor’s degree in Engineering or Science in related fields with a GPA of at least 2.7',
      'OR a pass with a minimum of three years of working experience',
    ],
    category: 'Master',
    faculty: 'Computer Studies',
    fee: 3585400, // From Table 4.3(a) for Tanzanian students (Semester I)
    careerOpportunities: [
      'IT Consultant',
      'Cybersecurity Specialist',
      'Data Analyst',
    ],
  ),
  Program(
    id: '64',
    name: 'Master of Computational Science and Engineering',
    description:
        'A postgraduate program focusing on computational techniques, including mathematical modeling and bioinformatics.',
    duration: '18 Months',
    requirements: [
      'Bachelor’s degree in Engineering or Science in related fields with a GPA of at least 2.7',
      'OR a pass with a minimum of three years of working experience',
    ],
    category: 'Master',
    faculty: 'Computer Studies',
    fee: 3585400, // From Table 4.3(a) for Tanzanian students (Semester I)
    careerOpportunities: [
      'Computational Scientist',
      'Data Scientist',
      'Research Engineer',
    ],
  ),
  Program(
    id: '65',
    name: 'Master of Engineering in Sustainable Energy Engineering',
    description:
        'A postgraduate program focusing on sustainable energy systems and environmental management.',
    duration: '18 Months',
    requirements: [
      'Bachelor’s degree in Engineering or Science in related fields with a GPA of at least 2.7',
      'OR a pass with a minimum of three years of working experience',
    ],
    category: 'Master',
    faculty: 'Mechanical Engineering',
    fee: 3585400, // From Table 4.3(c) for Tanzanian students (Semester I)
    careerOpportunities: [
      'Sustainable Energy Engineer',
      'Environmental Consultant',
      'Energy Systems Manager',
    ],
  ),
  Program(
    id: '66',
    name: 'Master of Engineering in Telecommunication Systems and Networks',
    description:
        'A postgraduate program covering advanced telecommunication systems and network engineering.',
    duration: '18 Months',
    requirements: [
      'Bachelor’s degree in Engineering or Science in related fields with a GPA of at least 2.7',
      'OR a pass with a minimum of three years of working experience',
    ],
    category: 'Master',
    faculty: 'Electrical Engineering',
    fee: 3585400, // From Table 4.3(a) for Tanzanian students (Semester I)
    careerOpportunities: [
      'Telecommunication Engineer',
      'Network Architect',
      'Systems Consultant',
    ],
  ),
];
