function fischer_data_entry
thisPath = [cd filesep];

subjectCode = input('Please enter the subject code: ','s');

sentences = {'The lucky actor.',...
'The furry caterpillar.',...
'Kindergarten is for children.',...
'Drowning in honey is impossible.'};

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
    check = 0;
    while check == 0
        fingers(i).h1f1 = upper(input('What was the first finger used on the first hand? ','s'));
        check = sum(ismember({'LT','LI','LM','LR','LP','RP','RR','RM','RI','RT'},fingers(i).h1f1));
        if check == 0
            disp('Please use the codes from the sheet')
        end
    end
    check = 0;
        while check == 0
    fingers(i).h2f1 = upper(input('What was the first finger used on the second hand? (enter na if a second hand wasn''t used) ','s'));
        check = sum(ismember({'LT','LI','LM','LR','LP','RP','RR','RM','RI','RT','NA'},fingers(i).h2f1));
        if check == 0
            disp('Please use the codes from the sheet (or NA if they only used one hand')
        end
    end
    check = 0;
   
    %fingers(i).h2f1 = upper(input('What was the first finger used on the second hand? (enter na if a second hand wasn''t used) ','s'));
    
    
    
    
   % f = {fingers(i).LT,fingers(i).LI,fingers(i).LM,fingers(i).LR,fingers(i).LP,...
   %         fingers(i).RP,fingers(i).RR,fingers(i).RM,fingers(i).RI,fingers(i).RT};
   % if sum(ismember(f,'1')) ~= 1
   %     error('You made an error entering the starting fingers! Please start again.');
   % end
   % if sum(~ismember(f,'n')) ~= sum(~ismember(unique(f),'n'))
   %    error('You have entered the same number for two fingers! Please start again.'); 
   % end
    
end

language = upper(input('What is the participant''s native language? (please give the language name in english) ','s'));

order = [a b c d];

reject = input('Did the participant correctly guess the nature of the experiment? ','s');


fingercountingData.reject = reject;
fingercountingData.order = order;
fingercountingData.fingers = fingers;
fingercountingData.subjectCode = subjectCode;

save([thisPath subjectCode '_fingercounting.mat'],'fingercountingData','-mat');
