LANGUAGE = 'dutch'

function fischer_data_entry
thisPath = [cd filesep];

subjectCode = input('Please enter the subject code: ','s');

if LANGUAGE == 'dutch'
	sentences = {'De blije acteur.',...
	'De lange dromedaris.',...
	'Peuterspeelzaal is voor peuters.',...
	'Springen in drijfzand is onmogelijk'};
else
	sentences = {'The lucky actor.',...
	'The furry caterpillar.',...
	'Kindergarten is for children.',...
	'Drowning in honey is impossible.'};
end

disp('Setences');
disp(['1. ' sentences{1}]);
disp(['2. ' sentences{2}]);
disp(['3. ' sentences{3}]);
disp(['4. ' sentences{4}]);
disp(' ');
a = input('Which sentence was first? (type 1-4) ');
if a <1 || a > 4
    error('You must enter 1 - 4')
end

b = input('Which sentence was second? (type 1-4) ');
if b <1 || b > 4
    error('You must enter 1 - 4')
end

c = input('Which sentence was third? (type 1-4) ');
if c <1 || c > 4
    error('You must enter 1 - 4')
end

d = input('Which sentence was fourth? (type 2-4) ');
if d <1 || d > 4
    error('You must enter 1 - 4')
end
if length(unique([a b c d])) < 4
    error('You have entered the same number twice. Please start again.')
end
fingers = struct;

for i = [a b c d]
    disp(['For the sentence: ' sentences{i}])
    fingers(i).LT = input('When was finger LT used (type 1 - 10, or n if it was not used) ','s');
    fingers(i).LI = input('When was finger LI used (type 1 - 10, or n if it was not used) ','s');
    fingers(i).LM = input('When was finger LM used (type 1 - 10, or n if it was not used) ','s');
    fingers(i).LR = input('When was finger LR used (type 1 - 10, or n if it was not used) ','s');
    fingers(i).LP = input('When was finger LP used (type 1 - 10, or n if it was not used) ','s');
    fingers(i).RP = input('When was finger RP used (type 1 - 10, or n if it was not used) ','s');
    fingers(i).RR = input('When was finger RR used (type 1 - 10, or n if it was not used) ','s');
    fingers(i).RM = input('When was finger RM used (type 1 - 10, or n if it was not used) ','s');
    fingers(i).RI = input('When was finger RI used (type 1 - 10, or n if it was not used) ','s');
    fingers(i).RT = input('When was finger RT used (type 1 - 10, or n if it was not used) ','s');

    f = {fingers(i).LT,fingers(i).LI,fingers(i).LM,fingers(i).LR,fingers(i).LP,...
            fingers(i).RP,fingers(i).RR,fingers(i).RM,fingers(i).RI,fingers(i).RT};
    if sum(ismember(f,'1')) ~= 1
        error('You made an error entering the starting fingers! Please start again.');
    end

    if sum(~ismember(f,'n')) ~= sum(~ismember(unique(f),'n'))
       error('You have entered the same number for two fingers! Please start again.'); 
    end
    
end

order = [a b c d];

reject = input('Did the participant correctly guess the nature of the experiment? ','s');


fingercountingData.reject = reject;
fingercountingData.order = order;
fingercountingData.fingers = fingers;
fingercountingData.subjectCode = subjectCode;

save([thisPath subjectCode '_fingercounting.mat'],'fingercountingData','-mat');
