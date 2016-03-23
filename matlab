clear;
clc;
initialY=1958;
endY=1990;
setdbprefs('datareturnformat','numeric')        %设置从数据库返回数据的格式-->数值型 极大提高运行的速率
conn = database.ODBCConnection('qixiang','','');%采用windows验证，用户名和密码均为空
number=[57504 56298];                           %气象站点编号
sqlquery1=['select year,month,day'...
        ' FROM [qixiang].[dbo].[qixiangDataRaw]'...
        ' WHERE stcd=52908'... 
        ' AND ([year] between '...
        int2str(initialY)...
        ' AND '...
        int2str(endY) ')'...
        ' ORDER BY stcd,year,month,day'];
curs1=exec(conn,sqlquery1);
curs1=fetch(curs1);
date=curs1.Data;
close(curs1);     %关闭游标1
M=size(date,1);   %数据长度
N=size(number,2); %站点数
Edata=zeros(M,6);
PMET0=zeros(M,N);
day=zeros(M,1);   %日序数
%设置日序数
a=1;
for i=1:M
    day(i)=a;
    a=a+1;
    if i==M
        break;
    end
    if date(i,1)~=date(i+1,1)
        a=1;
    end
end
%提取蒸发要素数据
for I=1:N
sqlquery2=['SELECT'...
	   ' [tMax]/10 as tMax'...
      ', [tMin]/10 as tMin'...
	  ', [tAvg]/10 as tAvg'...
      ', [humidityAvg] as humidityAvg'...
      ', [windAvg]/10 as windAvg'...
      ', [sunHour]/10 as sunHour'...
  ' FROM [qixiang].[dbo].[qixiangDataRaw]'...
  ' WHERE stcd='...
    int2str(number(I))...
  ' AND (year between '...
        int2str(initialY)...
        ' AND '...
        int2str(endY) ')'...
  ' ORDER BY year,month,day'];
curs2=exec(conn,sqlquery2);
curs2=fetch(curs2);
Edata=curs2.Data;
close(curs2);   %关闭游标2

%气象数据缺失值处理 
    for j=1:6
        for i=1:M
            if (Edata(i,j)>100)&&(i~=1)
                Edata(i,j)=(Edata(i-1,j)+Edata(i+1,j))/2;
                if Edata(i,j)>100
                    Edata(i,j)=0;
                end
            elseif Edata(i,j)>100
                Edata(i,j)=0;
            end
        end
    end
%提取站点纬度和高程
sqlquery3=['SELECT latitude'...
           ', [altitude]'...
           ' FROM [qixiang].[dbo].[qixiangStation]'...
           ' where stcd='...
             int2str(number(I))];
curs3=exec(conn,sqlquery3);
curs3=fetch(curs3);
lat_alt=curs3.Data;
close(curs3);   %关闭游标3

    %---计算PMET0---%
    %输入：
    tMax=Edata(:,1);
    tMin=Edata(:,2);
    tAvg=Edata(:,3);
    humAvg=Edata(:,4);
    windAvg=Edata(:,5);
    sunh=Edata(:,6);
    lat=lat_alt(1);
    height=lat_alt(2);
    %输出：
    esMax=0.611*exp((17.27*tMax)./(tMax+237.3));
    esMin=0.611*exp((17.27*tMin)./(tMin+237.3));
    esAvg=(esMax+esMin)./2;
    sigma=0.409.*sin(0.0172.*day-1.39);               %day为日序数
    temp1=acos(-tan(lat*3.1415926/180).*tan(sigma));  %lat纬度
    temp2=7.64*temp1;
    dr=1+0.033*cos(0.0172*day);
    Ra=37.6*dr.*(temp1.*sin(lat*3.1415926/180).*sin(sigma)+cos(lat*3.1415926/180)*cos(sigma).*sin(temp1));
    Rns=0.77*(0.25+0.5*sunh./temp2).*Ra;
    Tkx=tMax+273;
    Tkn=tMin+273;
    ed=humAvg.*esAvg/100;
    Rnl=2.45*10^(-9)*(0.9*sunh./temp2+0.1).*(0.34-0.14*sqrt(ed)).*(Tkx.^4+Tkn.^4);
    Rn=Rns-Rnl;
    pAvg=101.3*((293-0.0065*height)/293)^5.26;
    u2=4.87*windAvg/log(67.8*10-5.42);
    y=0.00163*pAvg/2.45;
    delta=4098*esAvg./(tAvg+237.3).^2;
    PMET0(:,I)=(0.408.*delta.*(Rn-0)+y.*900./(273+tAvg).*u2.*(esAvg-ed))./(delta+y.*(1+0.34.*u2));
end
PMEAvg=mean(PMET0,2);
close(conn);    %关闭数据库连接
sum=0;
t=1;
for i=1:M
sum=sum+PMEAvg(i);
if i==M
    PMET0mon(t)=sum;
    break;
end
if date(i,2)~=date(i+1,2)
    PMET0mon(t)=sum;
    t=t+1;
    sum=0;
end
end
PMET0mon=PMET0mon';
fileID=fopen('testE.txt','w');%输出为txt文件
fprintf(fileID,'% 4.2f\r\n',PMET0mon);
fclose(fileID);




