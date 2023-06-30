%Function approximation
clear
clc
close all

%%%%%%%%%%%
%algorlm.m
% A script comparing performance of 'trainlm' and 'traingd'
% traingd - batch gradient descent 
% trainlm - Levenberg - Marquardt
%%%%%%%%%%%
sigma=0.1;

%generation of examples and targets
x=0:0.05:3*pi; y=sin(x.^2)+sigma*randn(1,length(x));
p=con2seq(x); t=con2seq(y); % convert the data to a useful format

%creation of networks
net1=feedforwardnet(50,'traingda');
net2=feedforwardnet(50,'traingdx');
net2.iw{1,1}=net1.iw{1,1};  %set the same weights and biases for the networks 
net2.lw{2,1}=net1.lw{2,1};
net2.b{1}=net1.b{1};
net2.b{2}=net1.b{2};

%training and simulation
net1.trainParam.epochs=1;  % set the number of epochs for the training 
net2.trainParam.epochs=1;
net1=train(net1,p,t);   % train the networks
net2=train(net2,p,t);
a11=sim(net1,p); a21=sim(net2,p);  % simulate the networks with the input vector p

net1.trainParam.epochs=14;
net2.trainParam.epochs=14;
net1=train(net1,p,t);
net2=train(net2,p,t);
a12=sim(net1,p); a22=sim(net2,p);

net1.trainParam.epochs=985;
net2.trainParam.epochs=985;
net1=train(net1,p,t);
net2=train(net2,p,t);
a13=sim(net1,p); a23=sim(net2,p);

%plots
figure
subplot(3,3,1);
plot(x,y,'bx',x,cell2mat(a11),'r',x,cell2mat(a21),'g'); % plot the sine function and the output of the networks
title('1 epoch');
legend('target','trainlm','traingd','Location','north');
subplot(3,3,2);
postregm(cell2mat(a11),y); % perform a linear regression analysis and plot the result
subplot(3,3,3);
postregm(cell2mat(a21),y);
%
subplot(3,3,4);
plot(x,y,'bx',x,cell2mat(a12),'r',x,cell2mat(a22),'g');
title('15 epochs');
legend('target','trainlm','traingd','Location','north');
subplot(3,3,5);
postregm(cell2mat(a12),y);
subplot(3,3,6);
postregm(cell2mat(a22),y);
%
subplot(3,3,7);
plot(x,y,'bx',x,cell2mat(a13),'r',x,cell2mat(a23),'g');
title('1000 epochs');
legend('target','trainlm','traingd','Location','north');
subplot(3,3,8);
postregm(cell2mat(a13),y);
subplot(3,3,9);
postregm(cell2mat(a23),y);




%%%%MSE vs Epoch plot
%generation of examples and targets
x=0:0.01:3*pi; y=sin(x.^2)+sigma*randn(1,length(x));
p=con2seq(x); t=con2seq(y); % convert the data to a useful format

%creation of networks
netNum=7;
nets{1}=feedforwardnet(50,'traingd');
nets{2}=feedforwardnet(50,'traingda');
nets{3}=feedforwardnet(50,'traingdx');
nets{4}=feedforwardnet(50,'trainscg');
nets{5}=feedforwardnet(50,'trainbfg');
nets{6}=feedforwardnet(50,'trainlm');
nets{7}=feedforwardnet(50,'trainbr');


for i=1:netNum
    nets{i}.trainParam.epochs=1000;
    [nets{i},tr{i}]=train(nets{i},p,t);
    simulation{i}=sim(nets{i},p);
end

hold on;
for i=1:netNum
    plot(tr{i}.perf,'DisplayName',nets{i}.trainFcn,'LineWidth',1.5);
end
set(gca, 'YScale', 'log')
xlabel('Epoch');
ylabel('Mean Square Error');
hold off;

postregm(cell2mat(simulation{6}),y);
plot(x,y,'DisplayName','Training'); hold on; plot(x,cell2mat(simulation{6}),'DisplayName','Network'); hold off;


%%%%MSE vs Time plot
%generation of examples and targets
x=0:0.05:3*pi; y=sin(x.^2)+sigma*randn();
p=con2seq(x); t=con2seq(y); % convert the data to a useful format

%creation of networks
netNum=6;
nets{1}=feedforwardnet(50,'traingd');
nets{2}=feedforwardnet(50,'traingda');
nets{3}=feedforwardnet(50,'traingdx');
nets{4}=feedforwardnet(50,'trainscg');
nets{5}=feedforwardnet(50,'trainbfg');
nets{6}=feedforwardnet(50,'trainlm');
%nets{7}=feedforwardnet(50,'trainbr');

nTimeSamples=100;
time = zeros(netNum,nTimeSamples);
perf = zeros(netNum,nTimeSamples);

for timeSample=1:nTimeSamples
    for i=1:netNum
        nets{i}.trainParam.epochs=1;
        tic;
        [nets{i},tr{i}]=train(nets{i},p,t);
        time(i,timeSample) = time(i,max(timeSample-1,1))+toc;
        perf(i,timeSample) = tr{i}.perf(end);
        simulation{i}=sim(nets{i},p);
    end
end

hold on;
for i=1:netNum
    plot(time(i,:),perf(i,:),'DisplayName',nets{i}.trainFcn,'LineWidth',1.5);
end
set(gca, 'YScale', 'log')
xlabel('Time (s)');
ylabel('Mean Square Error');
hold off;

postregm(cell2mat(simulation{6}),y);



%Test set
xTest=0:0.001:3*pi; yTest=sin(xTest.^2)+sigma*randn(1,length(xTest));
pTest=con2seq(xTest); tTest=con2seq(yTest);
testSim=sim(nets{6},pTest);
postregm(cell2mat(testSim),yTest);
plot(xTest,yTest,'DisplayName','Test');
hold on;
plot(xTest,cell2mat(testSim),'DisplayName','Network');
hold off;
MSETest = mean((yTest-cell2mat(testSim)).^2);



%Plot MSEvsHiddenUnits in training and validation
maxHidden = 180;
for i=1:maxHidden
    nets{i} = feedforwardnet(i,'trainlm');
    nets{i}.trainParam.epochs=100;
    [nets{i},tr{i}]=train(nets{i},p,t);
    simulationTraining{i}=sim(nets{i},p);
    mseTraining{i} = mean((y-cell2mat(simulationTraining{i})).^2);
    simulationValidation{i}=sim(nets{i},pTest);
    mseValidation{i} = mean((yTest-cell2mat(simulationValidation{i})).^2);
    
    nets2{i} = feedforwardnet(i,'trainbr');
    nets2{i}.trainParam.epochs=100;
    [nets2{i},tr2{i}]=train(nets2{i},p,t);
    simulationTraining2{i}=sim(nets2{i},p);
    mseTraining2{i} = mean((y-cell2mat(simulationTraining2{i})).^2);
    simulationValidation2{i}=sim(nets2{i},pTest);
    mseValidation2{i} = mean((yTest-cell2mat(simulationValidation2{i})).^2);
end
plot(cell2mat(mseTraining),'DisplayName','TrainingLM');
hold on;
plot(cell2mat(mseValidation),'DisplayName','ValidationLM');
plot(cell2mat(mseTraining2),'DisplayName','TrainingBR');
plot(cell2mat(mseValidation2),'DisplayName','ValidationBR');
hold off;
set(gca, 'YScale', 'log')
xlabel('# Hidden Units');
ylabel('Mean Square Error');



%Plot MSEvsEpochs in training and validation
maxEpochs = 100;
nets = feedforwardnet(30,'trainlm');
nets2 = feedforwardnet(30,'trainbr');
for i=1:maxEpochs
    nets.trainParam.epochs=1;
    [nets,tr]=train(nets,p,t);
    simulationTraining{i}=sim(nets,p);
    mseTraining{i} = mean((y-cell2mat(simulationTraining{i})).^2);
    simulationValidation{i}=sim(nets,pTest);
    mseValidation{i} = mean((yTest-cell2mat(simulationValidation{i})).^2);
    
    nets2.trainParam.epochs=1;
    [nets2,tr2]=train(nets2,p,t);
    simulationTraining2{i}=sim(nets2,p);
    mseTraining2{i} = mean((y-cell2mat(simulationTraining2{i})).^2);
    simulationValidation2{i}=sim(nets2,pTest);
    mseValidation2{i} = mean((yTest-cell2mat(simulationValidation2{i})).^2);
end
plot(cell2mat(mseTraining),'DisplayName','TrainingLM');
hold on;
plot(cell2mat(mseValidation),'DisplayName','ValidationLM');
plot(cell2mat(mseTraining2),'DisplayName','TrainingBR');
plot(cell2mat(mseValidation2),'DisplayName','ValidationBR');
hold off;
set(gca, 'YScale', 'log')
xlabel('Epoch');
ylabel('Mean Square Error');



%Level Curves
x=1:0.05:10;
y=1:0.05:10;
[X,Y]=meshgrid(x,y);
Z=Y.*log(X)+X.*log(Y);
mesh(X,Y,Z);
hold on;
contour3(X,Y,Z);
hold off;