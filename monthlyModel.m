%---monthmodel.m---%
%��������ˮ��ƽ��ģ��
%���Ŵ��㷨��20���壩������
%����˶����2016/3/14
%����˶����2016/3/17
function R=monthlyModel(x)
global P;
global QT;
global EP;
global M; 
 %---����ˮ�����km2��
N1=288;  %372;         %�ʶ���ʱ�䳤��
Q1=zeros(N1,1);
for j=1:N1
    Q1(j)=QT(j);
end
r=zeros(20,1);
aC=x(:,1);            
aSC=x(:,2);
sum2=sum((Q1-mean(Q1).*ones(N1,1)).^2);
for i=1:20          %�Ŵ��㷨20�ĸ�����Ŀ
    C=aC(i);
    SC=aSC(i);
    E=zeros(N1,1);
    S=zeros(N1,1);
    Q=zeros(N1,1);
for t=1:N1         
    E(t)=C.*EP(t).*tanh(P(t)/EP(t));
        if t==1
            S0=(Q1(j)*30.4*23*3600)/(1000*M);            %ȡ��һ���µľ�����
            Q(t)=(S0+P(t)-E(t))*tanh((S0+P(t)-E(t))/SC);
            S(t)=S0+P(t)-E(t)-Q(t); 
            continue;
        end  
    Q(t)=(S(t-1)+P(t)-E(t))*tanh((S(t-1)+P(t)-E(t))/SC);
    S(t)=S(t-1)+P(t)-E(t)-Q(t);
    if S(t)<0
        S(t)=0;
    end   
end
for t=1:N1
    Q(t)=Q(t)*1000*M/(30.4*24*3600);
end
    sum1=sum((Q1-Q).^2);
    r(i)=1-sum1./sum2;
end
    R=r;
end
  


